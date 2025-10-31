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
#  processed_at                 :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_team_id              (team_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  include CSVImportable

  has_and_belongs_to_many :batches
  has_and_belongs_to_many :patient_locations
  has_and_belongs_to_many :sessions
  has_and_belongs_to_many :vaccination_records

  private

  def check_rows_are_unique
    # there is no uniqueness check for immunisations
  end

  def parse_row(data)
    ImmunisationImportRow.new(data:, team:)
  end

  def process_row(row)
    vaccination_record = row.to_vaccination_record
    count_column_to_increment = count_column(vaccination_record)
    return count_column_to_increment unless vaccination_record

    # Instead of saving individually, we'll collect the records
    @vaccination_records_batch ||= Set.new
    @batches_batch ||= Set.new
    @patients_batch ||= Set.new
    @patient_locations_batch ||= Set.new

    @vaccination_records_batch.add(vaccination_record)
    if (batch = vaccination_record.batch)
      @batches_batch.add(batch)
    end
    @patients_batch.add(vaccination_record.patient)

    if (patient_location = row.to_patient_location)
      @patient_locations_batch.add(patient_location)
    end

    count_column_to_increment
  end

  def bulk_import(rows: 100)
    return if rows != :all && @vaccination_records_batch.size < rows

    # We need to convert the batch to an array as `import` modifies the
    # objects to add IDs to any new records.
    vaccination_records = @vaccination_records_batch.to_a
    patient_locations = @patient_locations_batch.to_a

    VaccinationRecord.import(vaccination_records, on_duplicate_key_update: :all)

    vaccination_records.each do |vaccination_record|
      AlreadyHadNotificationSender.call(vaccination_record:)
    end

    PatientLocation.import(patient_locations, on_duplicate_key_ignore: :all)

    patient_locations.each(&:search_vaccinations_from_nhs_immunisations_api)

    [
      [:vaccination_records, vaccination_records],
      [:batches, @batches_batch],
      [:patients, @patients_batch],
      [:patient_locations, patient_locations.select { it.id.present? }]
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
    StatusUpdater.call(patient: patients)

    vaccination_records.sync_all_to_nhs_immunisations_api
  end
end
