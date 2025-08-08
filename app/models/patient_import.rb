# frozen_string_literal: true

class PatientImport < ApplicationRecord
  self.abstract_class = true

  private

  def check_rows_are_unique
    rows
      .map(&:nhs_number_value)
      .tally
      .each do |nhs_number, count|
        next if nhs_number.nil? || count <= 1

        rows
          .select { _1.nhs_number_value == nhs_number }
          .each do |row|
            row.errors.add(
              :base,
              "The same NHS number appears multiple times in this file."
            )
          end
      end
  end

  def process_row(row)
    parents = row.to_parents
    patient = row.to_patient
    parent_relationships = row.to_parent_relationships(parents, patient)

    @school_moves_to_confirm ||= Set.new
    @school_moves_to_save ||= Set.new

    if (school_move = row.to_school_move(patient))
      if (patient.school.nil? && !patient.home_educated) ||
           patient.not_in_team?(team:, academic_year:) ||
           patient.archived?(team:)
        @school_moves_to_confirm.add(school_move)
      else
        @school_moves_to_save.add(school_move)
      end
    end

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

    @school_moves_to_confirm.each do |school_move|
      # if the same patient appears multiple times in the file,
      # the duplicates won't be persisted
      school_move.confirm! if school_move.patient.persisted?
    end
    @school_moves_to_confirm.clear

    SchoolMove.import(@school_moves_to_save.to_a, on_duplicate_key_ignore: :all)
    @school_moves_to_save.clear
  end
end
