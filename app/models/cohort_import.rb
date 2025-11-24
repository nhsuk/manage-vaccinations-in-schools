# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports
#
#  id                           :bigint           not null, primary key
#  academic_year                :integer          not null
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  reviewed_at                  :datetime         default([]), not null, is an Array
#  reviewed_by_user_ids         :bigint           default([]), not null, is an Array
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
#  index_cohort_imports_on_team_id              (team_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class CohortImport < PatientImport
  include CSVImportable

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents
  has_many :changesets,
           class_name: "PatientChangeset",
           as: :import,
           dependent: :destroy
  has_many :pds_search_results

  def type_label
    "Child records"
  end

  def postprocess_rows!
    ids = changesets.pluck(:school_id).uniq.compact
    PatientsAgedOutOfSchoolJob.perform_bulk(ids.zip)
  end

  def post_commit!
  end

  private

  def parse_row(data)
    CohortImportRow.new(data:, team:, academic_year:)
  end
end
