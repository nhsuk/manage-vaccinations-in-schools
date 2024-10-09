# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                            :bigint           not null, primary key
#  changed_record_count          :integer
#  csv_data                      :text
#  csv_filename                  :text             not null
#  csv_removed_at                :datetime
#  exact_duplicate_record_count  :integer
#  new_record_count              :integer
#  not_administered_record_count :integer
#  recorded_at                   :datetime
#  rows_count                    :integer
#  serialized_errors             :jsonb
#  status                        :integer          default("pending_import"), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  programme_id                  :bigint           not null
#  team_id                       :bigint           not null
#  uploaded_by_user_id           :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_programme_id         (programme_id)
#  index_immunisation_imports_on_team_id              (team_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  include CSVImportable

  belongs_to :programme

  has_and_belongs_to_many :batches
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :patient_sessions
  has_and_belongs_to_many :patients
  has_and_belongs_to_many :sessions
  has_and_belongs_to_many :vaccination_records

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

  def count_columns
    %i[
      exact_duplicate_record_count
      new_record_count
      changed_record_count
      not_administered_record_count
    ]
  end

  def parse_row(data)
    ImmunisationImportRow.new(data:, programme:, user: uploaded_by)
  end

  def process_row(row)
    vaccination_record = row.to_vaccination_record
    count_column_to_increment = count_column(vaccination_record)
    return count_column_to_increment unless vaccination_record

    # Instead of saving individually, we'll collect the records
    @vaccination_records ||= []
    @vaccination_records << vaccination_record

    # We'll handle linking records after bulk import
    @records_to_link ||= []
    @records_to_link << [
      vaccination_record,
      vaccination_record.batch,
      vaccination_record.location,
      vaccination_record.patient,
      vaccination_record.patient_session,
      vaccination_record.session
    ]

    count_column_to_increment
  end

  def link_records(*records)
    records
      .reject(&:nil?)
      .each do |record|
        unless record.immunisation_imports.exists?(id)
          record.immunisation_imports << self
        end
      end
  end

  def record_rows
    Time.zone.now.tap do |recorded_at|
      patient_sessions.draft.update_all(active: true)
      patients.draft.update_all(recorded_at:)
      vaccination_records.draft.update_all(recorded_at:)
    end
  end

  def count_column(vaccination_record)
    if !vaccination_record
      :not_administered_record_count
    elsif vaccination_record.new_record? || vaccination_record.draft?
      :new_record_count
    elsif vaccination_record.pending_changes.any? ||
          vaccination_record.patient.pending_changes.any?
      :changed_record_count
    else
      :exact_duplicate_record_count
    end
  end

  def bulk_import(rows: 100)
    return if rows != :all && @vaccination_records.size < rows

    VaccinationRecord.import(
      @vaccination_records,
      on_duplicate_key_update: :all
    )

    # Link records after bulk import
    @records_to_link.each { |records| link_records(*records) }

    # Clear the arrays for the next batch
    @vaccination_records.clear
    @records_to_link.clear
  end
end
