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
  include CSVImportable
  include Recordable

  encrypts :csv_data

  belongs_to :user
  belongs_to :campaign
  with_options dependent: :restrict_with_exception,
               foreign_key: :imported_from_id do
    has_many :vaccination_records
    has_many :locations
    has_many :sessions
    has_many :patients
  end

  scope :csv_not_removed, -> { where(csv_removed_at: nil) }

  before_save :ensure_processed_with_count_statistics

  COUNT_COLUMNS = %i[
    exact_duplicate_record_count
    new_record_count
    not_administered_record_count
  ].freeze

  def csv_removed?
    csv_removed_at != nil
  end

  def processed?
    processed_at != nil
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
        if (patient_session = vaccination_record.patient_session).draft?
          patient_session.update!(active: true)
        end

        if (session = vaccination_record.session).draft?
          session.update!(draft: false)
        end

        vaccination_record.update!(recorded_at:)
      end

      update!(recorded_at:)
    end
  end

  def remove!
    return if csv_removed?
    update!(csv_data: nil, csv_removed_at: Time.zone.now)
  end

  private

  def required_headers
    %w[
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
    ]
  end

  def parse_row(row_data)
    ImmunisationImportRow.new(
      data: row_data,
      campaign:,
      user:,
      imported_from: self
    )
  end

  def ensure_processed_with_count_statistics
    if processed? && COUNT_COLUMNS.any? { |column| send(column).nil? }
      raise "Count statistics must be set for a processed import."
    elsif !processed? && COUNT_COLUMNS.any? { |column| !send(column).nil? }
      raise "Count statistics must not be set for a non-processed import."
    end
  end
end
