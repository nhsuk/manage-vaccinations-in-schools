# frozen_string_literal: true

class PatientImport < ApplicationRecord
  self.abstract_class = true

  private

  def required_headers
    %w[
      CHILD_ADDRESS_LINE_1
      CHILD_ADDRESS_LINE_2
      CHILD_ADDRESS_POSTCODE
      CHILD_ADDRESS_TOWN
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

    parents.each(&:save!)
    patient.save!
    parent_relationships.each(&:save!)

    link_records(*parents, *parent_relationships, patient)

    count_column_to_increment
  end

  def record_rows
    Time.zone.now.tap do |recorded_at|
      patients.draft.update_all(recorded_at:)
      parents.draft.update_all(recorded_at:)
    end
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
end
