# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id                 (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#

# The patient session model represents a patient who goes to the school or
# clinic location represented by the session. This doesn't necessarily mean
# that the patient is eligible for any of the programmes administered in any
# particular session they belong to.
#
# This is designed to support programmes being dynamically added or removed to
# sessions without needing to also create or destroy patient session
# instances. While also adding support for patients becoming eligible if year
# groups are added or removed to locations, again without needing to also
# create or destroy patient session instances.
#
# It also supports the scenario where a patient belongs to a session but is
# only eligible for one of many programmes administered in the session. In
# that case, the list of programmes they appear in won't be the same as the
# complete list of programmes administered in the session.

class PatientSession < ApplicationRecord
  audited associated_with: :patient
  has_associated_audits

  belongs_to :patient
  belongs_to :session

  has_many :session_attendances, dependent: :destroy
  has_one :registration_status

  has_one :location, through: :session
  has_one :subteam, through: :session
  has_one :team, through: :session
  has_one :organisation, through: :team

  has_many :gillick_assessments,
           -> { where(patient_id: it.patient_id) },
           through: :session

  has_many :notes, -> { where(session_id: it.session_id) }, through: :patient

  has_one :latest_note,
          -> { where(session_id: it.session_id).order(created_at: :desc) },
          through: :patient,
          source: :notes

  has_many :pre_screenings,
           -> { where(patient_id: it.patient_id) },
           through: :session

  has_many :session_notifications,
           -> { where(session_id: it.session_id) },
           through: :patient

  has_many :vaccination_records,
           -> { where(session_id: it.session_id) },
           through: :patient

  has_and_belongs_to_many :immunisation_imports

  scope :archived, ->(team:) { merge(Patient.archived(team:)) }

  scope :not_archived, ->(team:) { merge(Patient.not_archived(team:)) }

  scope :notification_not_sent,
        ->(session_date) do
          where.not(
            SessionNotification
              .where(
                "session_notifications.session_id = patient_sessions.session_id"
              )
              .where(
                "session_notifications.patient_id = patient_sessions.patient_id"
              )
              .where(session_date:)
              .arel
              .exists
          )
        end

  scope :appear_in_programmes,
        ->(programmes) do
          # Are any of the programmes administered in the session?
          programme_in_session =
            SessionProgramme
              .where(programme: programmes)
              .where("session_programmes.session_id = sessions.id")
              .arel
              .exists

          # Is the patient eligible for any of those programmes by year group?
          patient_in_administered_year_groups =
            LocationProgrammeYearGroup
              .where(programme: programmes)
              .where("location_id = sessions.location_id")
              .where(
                "year_group = sessions.academic_year " \
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

  scope :includes_programmes,
        -> do
          preload(
            :patient,
            session: %i[programmes location_programme_year_groups]
          )
        end

  scope :has_consent_status,
        ->(status, programme:, vaccine_method: nil) do
          consent_status_scope =
            Patient::ConsentStatus
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(status:, programme:)

          if vaccine_method
            consent_status_scope =
              consent_status_scope.has_vaccine_method(vaccine_method)
          end

          joins(:session).where(consent_status_scope.arel.exists)
        end

  scope :has_registration_status,
        ->(status) do
          where(
            PatientSession::RegistrationStatus
              .where("patient_session_id = patient_sessions.id")
              .where(status:)
              .arel
              .exists
          )
        end

  scope :has_triage_status,
        ->(status, programme:) do
          joins(:session).where(
            Patient::TriageStatus
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_vaccination_status,
        ->(status, programme:) do
          joins(:session).where(
            Patient::VaccinationStatus
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_vaccine_method,
        ->(vaccine_method, programme:) do
          joins(:session).where(
            Patient::TriageStatus
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(vaccine_method:, programme:)
              .arel
              .exists
          ).or(
            joins(:session).where(
              Patient::TriageStatus
                .where("patient_id = patient_sessions.patient_id")
                .where("academic_year = sessions.academic_year")
                .where(status: "not_required", programme:)
                .arel
                .exists
            ).where(
              Patient::ConsentStatus
                .where("patient_id = patient_sessions.patient_id")
                .where("academic_year = sessions.academic_year")
                .where(programme:)
                .has_vaccine_method(vaccine_method)
                .arel
                .exists
            )
          )
        end

  scope :consent_given_and_ready_to_vaccinate,
        ->(programmes:, vaccine_method:) do
          select do |patient_session|
            patient = patient_session.patient
            session = patient_session.session

            programmes.any? do |programme|
              patient.consent_given_and_safe_to_vaccinate?(
                programme:,
                academic_year: session.academic_year,
                vaccine_method:
              )
            end
          end
        end

  scope :without_patient_specific_direction,
        ->(programme:, team:) do
          joins(:session).where.not(
            PatientSpecificDirection
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(programme:, team:)
              .not_invalidated
              .arel
              .exists
          )
        end

  scope :has_patient_specific_direction,
        ->(programme:, team:) do
          joins(:session).where(
            PatientSpecificDirection
              .where("patient_id = patient_sessions.patient_id")
              .where("academic_year = sessions.academic_year")
              .where(programme:, team:)
              .not_invalidated
              .arel
              .exists
          )
        end

  scope :destroy_all_if_safe,
        -> do
          includes(
            :gillick_assessments,
            :session_attendances,
            :vaccination_records
          ).find_each(&:destroy_if_safe!)
        end

  delegate :academic_year, to: :session

  def has_patient_specific_direction?(**query)
    patient.has_patient_specific_direction?(academic_year:, **query)
  end

  def safe_to_destroy?
    vaccination_records.empty? && gillick_assessments.empty? &&
      session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def programmes = session.programmes_for(patient:, academic_year:)

  def todays_attendance
    if (session_date = session.session_dates.today.first)
      session_attendances.includes(:session_date).find_or_initialize_by(
        session_date:
      )
    end
  end

  def next_activity(programme:)
    if patient.vaccination_status(programme:, academic_year:).vaccinated?
      return nil
    end

    if patient.consent_given_and_safe_to_vaccinate?(programme:, academic_year:)
      return :record
    end

    if patient.triage_status(programme:, academic_year:).required?
      return :triage
    end

    consent_status = patient.consent_status(programme:, academic_year:)

    return :consent if consent_status.no_response? || consent_status.conflicts?

    :do_not_record
  end

  def outstanding_programmes
    if registration_status.nil? || registration_status.unknown? ||
         registration_status.not_attending?
      return []
    end

    any_programme_exists = vaccination_records.exists?(programme: programmes)

    # If this patient hasn't been seen yet by a nurse for any of the programmes,
    # we don't want to show the banner.
    return [] unless any_programme_exists

    programmes.select do |programme|
      !vaccination_records.exists?(programme:) &&
        patient.consent_given_and_safe_to_vaccinate?(programme:, academic_year:)
    end
  end
end
