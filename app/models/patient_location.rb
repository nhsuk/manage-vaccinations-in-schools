# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_locations
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  date_range    :daterange        default(-Infinity...Infinity)
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
  audited associated_with: :patient
  has_associated_audits

  belongs_to :patient
  belongs_to :location

  has_many :team_locations,
           -> { where(academic_year: it.academic_year) },
           through: :location

  has_many :sessions, through: :team_locations

  has_many :attendance_records,
           -> do
             where(patient_id: it.patient_id).for_academic_year(
               it.academic_year
             )
           end,
           through: :location

  has_many :gillick_assessments,
           -> do
             where(patient_id: it.patient_id).for_academic_year(
               it.academic_year
             )
           end,
           through: :location

  has_many :pre_screenings,
           -> do
             where(patient_id: it.patient_id).for_academic_year(
               it.academic_year
             )
           end,
           through: :location

  has_many :vaccination_records,
           -> { where(patient_id: it.patient_id) },
           through: :sessions

  has_and_belongs_to_many :immunisation_imports

  scope :current, -> { where(academic_year: AcademicYear.current) }
  scope :pending, -> { where(academic_year: AcademicYear.pending) }

  scope :joins_team_locations, -> { references(:teams_locations).joins(<<-SQL) }
    INNER JOIN team_locations
    ON team_locations.location_id = patient_locations.location_id
    AND team_locations.academic_year = patient_locations.academic_year
  SQL

  scope :joins_teams, -> { references(:teams).joins(<<-SQL) }
    INNER JOIN teams
    ON teams.id = team_locations.team_id
  SQL

  scope :joins_sessions, -> { joins_team_locations.joins(<<-SQL) }
    INNER JOIN sessions
    ON sessions.team_location_id = team_locations.id
    AND (patient_locations.date_range IS NULL OR sessions.dates = '{}'
        OR patient_locations.date_range @> ANY(sessions.dates))
  SQL

  scope :appear_in_programmes,
        ->(programmes) do
          where(
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
              .for_programmes(programmes)
              .arel
              .exists
          )
        end

  scope :destroy_all_if_safe,
        -> do
          preload(
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

  def begin_date
    value = date_range&.begin
    return nil if value.nil? || value == -Float::INFINITY
    value
  end

  def end_date
    value = date_range&.end
    return nil if value.nil? || value == Float::INFINITY
    date_range.exclude_end? ? value - 1.day : value
  end

  def begin_date=(value)
    self.date_range = Range.new(value, end_date)
  end

  def end_date=(value)
    self.date_range = Range.new(begin_date, value)
  end
end
