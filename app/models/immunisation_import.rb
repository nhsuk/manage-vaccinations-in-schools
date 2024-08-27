# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                            :bigint           not null, primary key
#  csv_data                      :text
#  csv_filename                  :text             not null
#  csv_removed_at                :datetime
#  exact_duplicate_record_count  :integer
#  new_record_count              :integer
#  not_administered_record_count :integer
#  processed_at                  :datetime
#  recorded_at                   :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campaign_id                   :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_campaign_id  (campaign_id)
#  index_immunisation_imports_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  include Recordable

  attr_accessor :csv_is_malformed, :data, :rows

  encrypts :csv

  belongs_to :user
  belongs_to :campaign
  with_options dependent: :restrict_with_exception,
               foreign_key: :imported_from_id do
    has_many :vaccination_records
    has_many :locations
    has_many :sessions
    has_many :patients
  end

  before_save :ensure_processed_with_count_statistics

  REQUIRED_HEADERS = %w[
    ORGANISATION_CODE
    SCHOOL_URN
    SCHOOL_NAME
    NHS_NUMBER
    PERSON_FORENAME
    PERSON_SURNAME
    PERSON_DOB
    PERSON_POSTCODE
    DATE_OF_VACCINATION
    VACCINE_GIVEN
    BATCH_NUMBER
    BATCH_EXPIRY_DATE
    ANATOMICAL_SITE
  ].freeze

  validates :csv_data, presence: true
  validates :csv_filename, presence: true

  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid
  validate :rows_are_valid

  COUNT_COLUMNS = %i[
    exact_duplicate_record_count
    new_record_count
    not_administered_record_count
  ].freeze

  def csv=(file)
    self.csv_data = file.read
    self.csv_filename = file.original_filename
  end

  def processed?
    processed_at != nil
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv_data, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  end

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows =
      data.map do |row_data|
        ImmunisationImportRow.new(
          data: row_data,
          campaign:,
          user:,
          imported_from: self
        )
      end
  end

  def process!
    return if processed?

    parse_rows! if rows.nil?
    return if invalid?

    stats = COUNT_COLUMNS.index_with { |_column| 0 }

    ActiveRecord::Base.transaction do
      save!

      rows.each do |row|
        if (vaccination_record = row.to_vaccination_record)
          if vaccination_record.new_record?
            vaccination_record.save!
            stats[:new_record_count] += 1
          else
            stats[:exact_duplicate_record_count] += 1
          end
        else
          stats[:not_administered_record_count] += 1
        end
      end

      update!(processed_at: Time.zone.now, **stats)
    end
  end

  def record!
    return if recorded?

    process! unless processed?
    return if invalid?

    recorded_at = Time.zone.now

    ActiveRecord::Base.transaction do
      vaccination_records.draft.each do |vaccination_record|
        if vaccination_record.session.draft?
          vaccination_record.session.update!(draft: false)
        end
        vaccination_record.update!(recorded_at:)
      end

      update!(recorded_at:)
    end
  end

  private

  def csv_is_valid
    return unless csv_is_malformed

    errors.add(:csv, :invalid)
  end

  def csv_has_records
    return unless data

    errors.add(:csv, :empty) if data.empty?
  end

  def headers_are_valid
    return unless data

    missing_headers = REQUIRED_HEADERS - data.headers
    errors.add(:csv, :missing_headers, missing_headers:) if missing_headers.any?
  end

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      if row.invalid?
        errors.add("row_#{index + 1}".to_sym, row.errors.full_messages)
      end
    end
  end

  def ensure_processed_with_count_statistics
    if processed? && COUNT_COLUMNS.any? { |column| send(column).nil? }
      raise "Count statistics must be set for a processed import."
    elsif !processed? && COUNT_COLUMNS.any? { |column| !send(column).nil? }
      raise "Count statistics must not be set for a non-processed import."
    end
  end
end
