# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
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
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  year_groups                  :integer          default([]), not null, is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  location_id                  :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_location_id          (location_id)
#  index_class_imports_on_team_id              (team_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ClassImport < PatientImport
  include CSVImportable

  belongs_to :location

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents
  has_many :changesets,
           class_name: "PatientChangeset",
           as: :import,
           dependent: :destroy
  has_many :pds_search_results

  def postprocess_rows!
    # Remove patients already in the sessions but not in the class list.
    birth_academic_years =
      year_groups.map { it.to_birth_academic_year(academic_year:) }

    existing_patients =
      Patient.where(birth_academic_year: birth_academic_years).where(
        PatientLocation
          .joins(:location)
          .where("patient_id = patients.id")
          .where(academic_year:, location:)
          .arel
          .exists
      )

    unknown_patients = existing_patients - patients

    school_moves =
      unknown_patients.map do |patient|
        SchoolMove.new(
          academic_year:,
          home_educated: false,
          patient:,
          source: "class_list_import",
          team:
        )
      end

    @imported_school_move_ids ||= []
    @imported_school_move_ids |=
      SchoolMove.import!(school_moves, on_duplicate_key_ignore: true).ids

    PatientsAgedOutOfSchoolJob.perform_async(location_id)
  end

  def post_commit!
    SyncPatientTeamJob.perform_later(SchoolMove, @imported_school_move_ids)
  end

  private

  def parse_row(data)
    ClassImportRow.new(data:, team:, academic_year:, location:, year_groups:)
  end
end
