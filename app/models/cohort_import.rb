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
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_team_id              (team_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class CohortImport < ApplicationRecord
  include CSVImportable

  belongs_to :team

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
      CHILD_ADDRESS_LINE_1
      CHILD_ADDRESS_LINE_2
      CHILD_ADDRESS_POSTCODE
      CHILD_ADDRESS_TOWN
      CHILD_COMMON_NAME
      CHILD_DATE_OF_BIRTH
      CHILD_FIRST_NAME
      CHILD_LAST_NAME
      CHILD_NHS_NUMBER
      <<<<<<<
      HEAD
      PARENT_EMAIL
      PARENT_NAME
      PARENT_PHONE
      PARENT_RELATIONSHIP
      |||||||
      parent
      of
      3f521a71
      (Rename
      cohort
      parent
      columns)
      =======
      PARENT_1_EMAIL
      PARENT_1_NAME
      PARENT_1_PHONE
      PARENT_1_RELATIONSHIP
      SCHOOL_NAME
      >>>>>>>
      3f521a71
      (Rename
      cohort
      parent
      columns)
      SCHOOL_URN
    ]
  end

  def count_columns
    %i[new_record_count changed_record_count exact_duplicate_record_count]
  end

  def parse_row(row_data)
    CohortImportRow.new(data: row_data, team:)
  end

  def process_row(row)
    parents = row.to_parents
    patient = row.to_patient
    parent_relationships = row.to_parent_relationships(parents, patient)

    count_column_to_increment =
      (
        if parents.any?(&:new_record?) || patient.new_record? ||
             parent_relationships.any?(&:new_record?)
          :new_record_count
        elsif parents.any?(&:changed?) || patient.changed? ||
              parent_relationships.any?(&:changed?)
          :changed_record_count
        else
          :exact_duplicate_record_count
        end
      )

    parents.each(&:save!)
    patient.save!
    parent_relationships.each(&:save!)

    link_records(*parents, *parent_relationships, patient)

    count_column_to_increment
  end

  def link_records(*records)
    records.each do |record|
      record.cohort_imports << self unless record.cohort_imports.exists?(id)
    end
  end

  def record_rows
    Time.zone.now.tap do |recorded_at|
      patients.draft.update_all(recorded_at:)
      parents.draft.update_all(recorded_at:)
    end
  end
end
