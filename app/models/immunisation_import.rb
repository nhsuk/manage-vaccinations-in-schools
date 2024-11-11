# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text             not null
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  recorded_at                  :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  programme_id                 :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_organisation_id      (organisation_id)
#  index_immunisation_imports_on_programme_id         (programme_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  include CSVImportable

  belongs_to :programme

  has_and_belongs_to_many :batches
  has_and_belongs_to_many :patient_sessions
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

  def parse_row(data)
    ImmunisationImportRow.new(data:, organisation:, programme:)
  end

  def process_row(row)
    vaccination_record = row.to_vaccination_record
    count_column_to_increment = count_column(vaccination_record)
    return count_column_to_increment unless vaccination_record

    # Instead of saving individually, we'll collect the records
    @vaccination_records_batch ||= Set.new
    @batches_batch ||= Set.new
    @patients_batch ||= Set.new
    @patient_sessions_batch ||= Set.new
    @sessions_batch ||= Set.new

    @vaccination_records_batch.add(vaccination_record)
    if vaccination_record.administered?
      @batches_batch.add(vaccination_record.batch)
    end
    @patients_batch.add(vaccination_record.patient)
    @patient_sessions_batch.add(vaccination_record.patient_session)
    @sessions_batch.add(vaccination_record.session)

    count_column_to_increment
  end

  def bulk_import(rows: 100)
    return if rows != :all && @vaccination_records_batch.size < rows

    # We need to convert the batch to an array as `import` modifies the
    # objects to add IDs to any new records.
    vaccination_records = @vaccination_records_batch.to_a

    VaccinationRecord.import(vaccination_records, on_duplicate_key_update: :all)

    [
      [:vaccination_records, vaccination_records],
      [:batches, @batches_batch],
      [:patients, @patients_batch],
      [:patient_sessions, @patient_sessions_batch],
      [:sessions, @sessions_batch]
    ].each do |association, collection|
      link_records_by_type(association, collection)
      collection.clear
    end

    @vaccination_records_batch.clear
  end

  def count_column(vaccination_record)
    if vaccination_record.new_record?
      :new_record_count
    elsif vaccination_record.pending_changes.any? ||
          vaccination_record.patient.pending_changes.any?
      :changed_record_count
    else
      :exact_duplicate_record_count
    end
  end

  def postprocess_rows!
    # Remove patients from upcoming sessions who have already been vaccinated.

    already_vaccinated_patients =
      patients
        .includes(:vaccination_records)
        .select { _1.vaccinated?(programme) }

    PatientSession.where(
      session: organisation.sessions.upcoming,
      patient: already_vaccinated_patients
    ).find_each(&:destroy_if_safe!)
  end
end
