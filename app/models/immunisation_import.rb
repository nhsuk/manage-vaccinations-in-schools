# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id          :bigint           not null, primary key
#  csv         :text             not null
#  recorded_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  user_id     :bigint           not null
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

  validates :csv, presence: true
  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid
  validate :rows_are_valid

  def csv=(value)
    super(value.respond_to?(:read) ? value.read : value)
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  ensure
    csv.close if csv.respond_to?(:close)
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
    parse_rows! if rows.nil?
    return if invalid?

    stats = { new_count: 0, duplicate_count: 0, ignored_count: 0 }

    ActiveRecord::Base.transaction do
      rows.each_with_object(stats) do |row, hash|
        if (vaccination_record = row.to_vaccination_record)
          if vaccination_record.new_record?
            vaccination_record.save!
            hash[:new_count] += 1
          else
            hash[:duplicate_count] += 1
          end
        else
          hash[:ignored_count] += 1
        end
      end
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
end
