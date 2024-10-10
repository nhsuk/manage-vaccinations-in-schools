# frozen_string_literal: true

class PatientImport < ApplicationRecord
  self.abstract_class = true

  private

  def required_headers
    %w[
      CHILD_ADDRESS_LINE_1
      CHILD_ADDRESS_LINE_2
      CHILD_POSTCODE
      CHILD_TOWN
      CHILD_COMMON_NAME
      CHILD_DATE_OF_BIRTH
      CHILD_FIRST_NAME
      CHILD_LAST_NAME
      CHILD_NHS_NUMBER
      PARENT_1_EMAIL
      PARENT_1_NAME
      PARENT_1_PHONE
      PARENT_1_RELATIONSHIP
      PARENT_2_EMAIL
      PARENT_2_NAME
      PARENT_2_PHONE
      PARENT_2_RELATIONSHIP
    ]
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
    relationships = @relationships_batch.to_a

    Parent.import(parents, on_duplicate_key_update: :all)

    patients.each { |patient| patient.run_callbacks(:save) { false } }
    Patient.import(patients, on_duplicate_key_update: :all)

    ParentRelationship.import(relationships, on_duplicate_key_update: :all)

    link_records_by_type(:patients, patients)
    link_records_by_type(:parents, parents)
    link_records_by_type(:parent_relationships, relationships)

    # Clear the sets for the next batch
    @parents_batch.clear
    @patients_batch.clear
    @relationships_batch.clear
  end
end
