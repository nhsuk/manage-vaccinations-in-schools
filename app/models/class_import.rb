# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  rows_count                   :integer
#  serialized_errors            :json
#  status                       :integer          default("pending_import"), not null
#  year_groups                  :integer          default([]), not null, is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  session_id                   :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_organisation_id      (organisation_id)
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ClassImport < PatientImport
  include CSVImportable

  belongs_to :session

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents

  private

  def parse_row(data)
    ClassImportRow.new(data:, session:, year_groups:)
  end

  def birth_academic_years
    year_groups.map(&:to_birth_academic_year)
  end

  def postprocess_rows!
    # Remove patients already in the session but not in the class list.

    unknown_patients =
      session.patients.where(birth_academic_year: birth_academic_years) -
        patients

    school_moves =
      unknown_patients.map do |patient|
        SchoolMove.new(
          patient:,
          source: :class_list_import,
          home_educated: false,
          organisation:
        )
      end

    SchoolMove.import(school_moves, on_duplicate_key_ignore: true)
  end
end
