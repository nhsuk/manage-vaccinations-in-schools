# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class CohortImport < ApplicationRecord
  include CSVImportable

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents
  has_and_belongs_to_many :patients

  def processed_only_exact_duplicates?
    new_record_count.zero? && changed_record_count.zero? &&
      exact_duplicate_record_count != 0
  end

  private

  def required_headers
    %w[
      SCHOOL_URN
      SCHOOL_NAME
      PARENT_NAME
      PARENT_RELATIONSHIP
      PARENT_EMAIL
      PARENT_PHONE
      CHILD_FIRST_NAME
      CHILD_LAST_NAME
      CHILD_COMMON_NAME
      CHILD_DATE_OF_BIRTH
      CHILD_ADDRESS_LINE_1
      CHILD_ADDRESS_LINE_2
      CHILD_ADDRESS_TOWN
      CHILD_ADDRESS_POSTCODE
      CHILD_NHS_NUMBER
    ]
  end

  def count_columns
    %i[new_record_count changed_record_count exact_duplicate_record_count]
  end

  def parse_row(row_data)
    CohortImportRow.new(data: row_data)
  end

  def process_row(row)
    parent = row.to_parent
    patient = row.to_patient
    parent_relationship = row.to_parent_relationship(parent, patient)

    count_column_to_increment =
      (
        if parent.new_record? || patient.new_record? ||
             parent_relationship.new_record?
          :new_record_count
        elsif parent.changed? || patient.changed? ||
              parent_relationship.changed?
          :changed_record_count
        else
          :exact_duplicate_record_count
        end
      )

    parent.save!
    patient.save!
    parent_relationship.save!

    link_records(parent, patient, parent_relationship)

    count_column_to_increment
  end

  def link_records(*records)
    records.each do |record|
      record.cohort_imports << self unless record.cohort_imports.exists?(id)
    end
  end

  def record_rows
    # TODO: mark patients as recorded

    parents.draft.update_all(recorded_at: Time.zone.now)
  end
end
