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

  scope :archived, ->(team:) { merge(Patient.archived(team:)) }

  scope :not_archived, ->(team:) { merge(Patient.not_archived(team:)) }

  scope :joins_sessions, -> { joins(<<-SQL) }
      INNER JOIN sessions
      ON sessions.location_id = patient_locations.location_id
      AND sessions.academic_year = patient_locations.academic_year
    SQL

  scope :appear_in_programmes,
        ->(programmes) do
          # Are any of the programmes administered in the session?
          programme_in_session =
            SessionProgramme
              .joins(:session)
              .where(programme: programmes)
              .where("sessions.location_id = patient_locations.location_id")
              .where("sessions.academic_year = patient_locations.academic_year")
              .arel
              .exists

          # Is the patient eligible for any of those programmes by year group?
          patient_in_administered_year_groups =
            LocationProgrammeYearGroup
              .where(programme: programmes)
              .where(
                "location_programme_year_groups.location_id = patient_locations.location_id"
              )
              .where(
                "year_group = patient_locations.academic_year " \
                  "- patients.birth_academic_year " \
                  "- #{Integer::AGE_CHILDREN_START_SCHOOL}"
              )
              .arel
              .exists

          where(programme_in_session).where(patient_in_administered_year_groups)
        end

  scope :search_by_name,
        ->(name) { joins(:patient).merge(Patient.search_by_name(name)) }

  scope :search_by_year_groups,
        ->(year_groups, academic_year:) do
          joins(:patient).merge(
            Patient.search_by_year_groups(year_groups, academic_year:)
          )
        end

  scope :search_by_date_of_birth_year,
        ->(year) do
          where("extract(year from patients.date_of_birth) = ?", year)
        end

  scope :search_by_date_of_birth_month,
        ->(month) do
          where("extract(month from patients.date_of_birth) = ?", month)
        end

  scope :search_by_date_of_birth_day,
        ->(day) { where("extract(day from patients.date_of_birth) = ?", day) }

  scope :search_by_nhs_number,
        ->(nhs_number) { merge(Patient.search_by_nhs_number(nhs_number)) }

  scope :order_by_name,
        -> do
          joins(:patient).order(
            "LOWER(patients.family_name)",
            "LOWER(patients.given_name)"
          )
        end

  scope :has_consent_status,
        ->(status, programme:, vaccine_method: nil) do
          consent_status_scope =
            Patient::ConsentStatus
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(status:, programme:)

          if vaccine_method
            consent_status_scope =
              consent_status_scope.has_vaccine_method(vaccine_method)
          end

          where(consent_status_scope.arel.exists)
        end

  scope :has_registration_status,
        ->(status, session:) do
          where(
            Patient::RegistrationStatus
              .where("patient_id = patient_locations.patient_id")
              .where(session:, status:)
              .arel
              .exists
          )
        end

  scope :has_triage_status,
        ->(status, programme:) do
          where(
            Patient::TriageStatus
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_vaccination_status,
        ->(status, programme:) do
          where(
            Patient::VaccinationStatus
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_vaccine_method,
        ->(vaccine_method, programme:) do
          where(
            Patient::TriageStatus
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(vaccine_method:, programme:)
              .arel
              .exists
          ).or(
            where(
              Patient::TriageStatus
                .where("patient_id = patient_locations.patient_id")
                .where("academic_year = patient_locations.academic_year")
                .where(status: "not_required", programme:)
                .arel
                .exists
            ).where(
              Patient::ConsentStatus
                .where("patient_id = patient_locations.patient_id")
                .where("academic_year = patient_locations.academic_year")
                .where(programme:)
                .has_vaccine_method(vaccine_method)
                .arel
                .exists
            )
          )
        end

  scope :consent_given_and_ready_to_vaccinate,
        ->(programmes:, academic_year:, vaccine_method:) do
          select do |patient_location|
            patient = patient_location.patient

            programmes.any? do |programme|
              patient.consent_given_and_safe_to_vaccinate?(
                programme:,
                academic_year:,
                vaccine_method:
              )
            end
          end
        end

  scope :without_patient_specific_direction,
        ->(programme:, team:) do
          where.not(
            PatientSpecificDirection
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(programme:, team:)
              .not_invalidated
              .arel
              .exists
          )
        end

  scope :has_patient_specific_direction,
        ->(programme:, team:) do
          where(
            PatientSpecificDirection
              .where("patient_id = patient_locations.patient_id")
              .where("academic_year = patient_locations.academic_year")
              .where(programme:, team:)
              .not_invalidated
              .arel
              .exists
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
