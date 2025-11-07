# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  home_educated :boolean
#  source        :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  patient_id    :bigint           not null
#  school_id     :bigint
#  team_id       :bigint
#
# Indexes
#
#  index_school_moves_on_patient_id                (patient_id) UNIQUE
#  index_school_moves_on_patient_id_and_school_id  (patient_id,school_id)
#  index_school_moves_on_school_id                 (school_id)
#  index_school_moves_on_team_id                   (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#
class SchoolMove < ApplicationRecord
  include ContributesToPatientTeams
  include Schoolable

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :patient

  belongs_to :patient

  belongs_to :team, optional: true

  enum :source,
       { parental_consent_form: 0, class_list_import: 1, cohort_import: 2 },
       prefix: true,
       validate: true

  validates :team,
            presence: {
              if: -> { school.nil? }
            },
            absence: {
              unless: -> { school.nil? }
            }

  def assign_from(school:, home_educated:, team:)
    if school
      assign_attributes(school:, home_educated: nil, team: nil)
    else
      assign_attributes(school: nil, home_educated:, team:)
    end
  end

  def confirm!(user: nil)
    imported_archive_reason_ids = []
    ActiveRecord::Base.transaction do
      update_patient!
      imported_archive_reason_ids = update_archive_reasons!(user:)
      update_sessions!
      create_log_entry!(user:)
      destroy! if persisted?
    end
    SyncPatientTeamJob.perform_later(ArchiveReason, imported_archive_reason_ids)
  end

  def ignore!
    destroy! if persisted?
  end

  private

  def update_patient!
    patient.update!(home_educated:, school:)
  end

  def update_archive_reasons!(user:)
    new_team_id = school&.team&.id || team_id

    patient.archive_reasons.where(team_id: new_team_id).destroy_all

    archive_reasons =
      patient.teams.find_each.filter_map do |team|
        next if team.id == new_team_id

        ArchiveReason.new(
          patient_id:,
          team_id: team.id,
          type: "moved_out_of_area",
          created_by: user
        )
      end

    ArchiveReason.import!(archive_reasons, on_duplicate_key_ignore: true).ids
  end

  def update_sessions!
    patient
      .patient_locations
      .where("academic_year >= ?", academic_year)
      .destroy_all_if_safe

    location = school || team.generic_clinic

    PatientLocation.find_or_create_by!(patient:, location:, academic_year:)

    StatusUpdater.call(patient:)
  end

  def create_log_entry!(user:)
    SchoolMoveLogEntry.create!(home_educated:, patient:, school:, user:)
  end
end
