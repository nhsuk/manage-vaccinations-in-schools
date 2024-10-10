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
#  recorded_at                  :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  programme_id                 :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_programme_id         (programme_id)
#  index_cohort_imports_on_team_id              (team_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class CohortImport < PatientImport
  include CSVImportable

  belongs_to :programme

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents
  has_and_belongs_to_many :patients

  private

  def required_headers
    super + %w[CHILD_SCHOOL_URN]
  end

  def parse_row(data)
    CohortImportRow.new(data:, team:, programme:)
  end

  def postprocess_rows!
    team
      .sessions
      .has_programme(programme)
      .upcoming
      .find_each(&:create_patient_sessions!)
  end
end
