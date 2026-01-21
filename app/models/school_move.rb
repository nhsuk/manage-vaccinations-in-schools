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
  include Schoolable
  include SchoolMovesHelper

  audited associated_with: :patient

  belongs_to :patient

  belongs_to :team, optional: true

  has_many :school_team_locations,
           -> do
             where(academic_year: it.academic_year).order(created_at: :desc)
           end,
           through: :school,
           source: :team_locations,
           class_name: "TeamLocation"

  has_many :school_teams,
           through: :school_team_locations,
           source: :team,
           class_name: "Team"

  scope :joins_team_locations_for_school, -> { joins(<<-SQL) }
    INNER JOIN team_locations
    ON team_locations.location_id = school_moves.school_id
    AND team_locations.academic_year = school_moves.academic_year
  SQL

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
    old_teams = patient.school.teams if from_another_team?

    ActiveRecord::Base.transaction do
      update_patient!
      update_archive_reasons!(user:)
      update_locations!

      log_entry = create_log_entry!(user:)
      create_important_notice!(old_teams, log_entry) if old_teams

      destroy! if persisted?
    end
  end

  def ignore!
    destroy! if persisted?
  end

  def from_another_team?
    return false unless patient.school && school && patient.school.teams.any?

    (school.teams & patient.school.teams).empty?
  end

  private

  def update_patient!
    patient.update!(home_educated:, school:)
  end

  def update_archive_reasons!(user:)
    new_team_ids = (school_teams.map(&:id) + [team_id]).compact

    patient.archive_reasons.where(team_id: new_team_ids).destroy_all

    archive_reasons =
      patient.teams.find_each.filter_map do |team|
        next if team.id.in?(new_team_ids)

        ArchiveReason.new(
          patient_id:,
          team_id: team.id,
          type: "moved_out_of_area",
          created_by: user
        )
      end

    ArchiveReason.import!(archive_reasons, on_duplicate_key_ignore: true).ids
  end

  def update_locations!
    location = school || team.generic_clinic

    patient_locations = []

    patient
      .patient_locations
      .where("academic_year >= ?", academic_year)
      .where.not(location:)
      .find_each do |patient_location|
        end_date = Date.yesterday

        patient_location.end_date = end_date

        # It is possible for a patient to join and school and then at some
        #  point later that day be removed from it.
        if patient_location.begin_date && patient_location.begin_date > end_date
          patient_location.begin_date = end_date
        end

        patient_locations << patient_location
      end

    PatientLocation
      .find_or_initialize_by(patient:, location:, academic_year:)
      .tap do |patient_location|
        patient_location.end_date = nil

        # We only want to change the date if this is a new patient location
        #  for this patient, or if the existing patient location already has
        #  a start date. This is because if there's an existing patient
        #  location without a start date, changing the date will take the
        #  patient out of existing sessions.
        if patient_location.new_record? || patient_location.begin_date&.past?
          patient_location.begin_date = Date.current
        end

        patient_locations << patient_location
      end

    PatientLocation.import!(
      patient_locations,
      on_duplicate_key_update: {
        conflict_target: %i[patient_id location_id academic_year],
        columns: %i[date_range]
      }
    )

    PatientTeamUpdater.call(patient_scope: Patient.where(id: patient.id))
    StatusUpdater.call(patient:)
  end

  def create_log_entry!(user:)
    SchoolMoveLogEntry.create!(home_educated:, patient:, school:, user:)
  end

  def create_important_notice!(old_teams, school_move_log_entry)
    old_teams.each do |old_team|
      ImportantNotice.team_changed.find_or_create_by!(
        patient:,
        team: old_team,
        type: :team_changed,
        recorded_at: school_move_log_entry.created_at,
        school_move_log_entry:
      )
    end
  end
end
