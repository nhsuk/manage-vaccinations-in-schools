# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_locations
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :bigint           not null
#  patient_id    :bigint           not null
#
# Indexes
#
#  idx_on_location_id_academic_year_patient_id_3237b32fa0    (location_id,academic_year,patient_id) UNIQUE
#  idx_on_patient_id_location_id_academic_year_08a1dc4afe    (patient_id,location_id,academic_year) UNIQUE
#  index_patient_locations_on_location_id                    (location_id)
#  index_patient_locations_on_location_id_and_academic_year  (location_id,academic_year)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#

class PatientLocation < ApplicationRecord
  include ContributesToPatientTeams

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :patient
  has_associated_audits

  belongs_to :patient
  belongs_to :location

  has_many :sessions,
           -> { where(academic_year: it.academic_year) },
           through: :location,
           class_name: "Session"

  has_one :organisation, through: :location
  has_one :subteam, through: :location
  has_one :team, through: :location

  has_many :attendance_records,
           -> { where(patient_id: it.patient_id) },
           through: :location

  has_many :gillick_assessments,
           -> { where(patient_id: it.patient_id) },
           through: :sessions

  has_many :pre_screenings,
           -> { where(patient_id: it.patient_id) },
           through: :sessions

  has_many :vaccination_records,
           -> { where(patient_id: it.patient_id) },
           through: :sessions

  has_and_belongs_to_many :immunisation_imports

  scope :current, -> { where(academic_year: AcademicYear.current) }
  scope :pending, -> { where(academic_year: AcademicYear.pending) }

  scope :joins_sessions, -> { joins(<<-SQL) }
    INNER JOIN sessions
    ON sessions.location_id = patient_locations.location_id
    AND sessions.academic_year = patient_locations.academic_year
  SQL

  scope :appear_in_programmes,
        ->(programmes) do
          session_programme_exists =
            SessionProgramme
              .where(programme: programmes)
              .joins(:session)
              .where("sessions.location_id = patient_locations.location_id")
              .where("sessions.academic_year = patient_locations.academic_year")
              .arel
              .exists

          location_programme_year_group_exists =
            Location::ProgrammeYearGroup
              .joins(:location_year_group)
              .where(
                "location_year_groups.location_id = patient_locations.location_id"
              )
              .where(
                "location_year_groups.academic_year = patient_locations.academic_year"
              )
              .where(
                "location_year_groups.value = " \
                  "patient_locations.academic_year - patients.birth_academic_year - ?",
                Integer::AGE_CHILDREN_START_SCHOOL
              )
              .where(programme: programmes)
              .arel
              .exists

          where(session_programme_exists).where(
            location_programme_year_group_exists
          )
        end

  scope :destroy_all_if_safe,
        -> do
          includes(
            :attendance_records,
            :gillick_assessments,
            :pre_screenings,
            :vaccination_records
          ).find_each(&:destroy_if_safe!)
        end

  def safe_to_destroy?
    attendance_records.none?(&:attending?) && gillick_assessments.empty? &&
      pre_screenings.empty? && vaccination_records.empty?
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end
end
