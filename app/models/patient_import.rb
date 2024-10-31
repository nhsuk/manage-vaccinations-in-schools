# frozen_string_literal: true

class PatientImport < ApplicationRecord
  self.abstract_class = true

  private

  def required_headers
    %w[CHILD_POSTCODE CHILD_DATE_OF_BIRTH CHILD_FIRST_NAME CHILD_LAST_NAME]
  end

  def count_columns
    %i[new_record_count changed_record_count exact_duplicate_record_count]
  end

  def process_row(row)
    parents = row.to_parents
    patient = row.to_patient
    parent_relationships = row.to_parent_relationships(parents, patient)

    count_column_to_increment =
      count_column(patient, parents, parent_relationships)

    # Instead of saving individually, we'll collect the records
    @parents_batch ||= Set.new
    @patients_batch ||= Set.new
    @relationships_batch ||= Set.new

    @parents_batch.merge(parents)
    @patients_batch.add(patient)
    @relationships_batch.merge(parent_relationships)

    count_column_to_increment
  end

  def count_column(patient, parents, parent_relationships)
    if patient.new_record? || parents.any?(&:new_record?) ||
         parent_relationships.any?(&:new_record?)
      :new_record_count
    elsif patient.changed? || parents.any?(&:changed?) ||
          parent_relationships.any?(&:changed?)
      :changed_record_count
    else
      :exact_duplicate_record_count
    end
  end

  def bulk_import(rows: 100)
    return if rows != :all && @patients_batch.size < rows

    # We need to convert the batches to arrays as `import` modifies the
    # objects to add IDs to any new records.

    parents = @parents_batch.to_a
    patients = @patients_batch.to_a
    relationships = @relationships_batch.to_a.uniq { [_1.parent, _1.patient] }

    Parent.import(parents, on_duplicate_key_update: :all)

    # To handle if the same NHS number appears in the batch we need to
    # remove duplicates, and then re-assign any relationships.

    patients_by_nhs_number = {}

    patients.reject! do |patient|
      next false if patient.nhs_number.blank?

      if patient.persisted?
        patients_by_nhs_number[patient.nhs_number] = patient
        next false
      elsif (existing_patient = patients_by_nhs_number[patient.nhs_number])
        relationships
          .select { _1.patient == patient }
          .each { _1.patient = existing_patient }
        next true
      else
        patients_by_nhs_number[patient.nhs_number] = patient
        next false
      end
    end

    Patient.import(patients, on_duplicate_key_update: :all)

    ParentRelationship.import(
      relationships,
      on_duplicate_key_update: {
        conflict_target: %i[parent_id patient_id],
        columns: %i[type other_name]
      }
    )

    link_records_by_type(:patients, patients)
    link_records_by_type(:parents, parents)
    link_records_by_type(:parent_relationships, relationships)

    # Clear the sets for the next batch
    @parents_batch.clear
    @patients_batch.clear
    @relationships_batch.clear
  end
end
