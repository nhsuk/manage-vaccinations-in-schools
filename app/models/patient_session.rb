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

class PatientSession < ApplicationRecord
  audited associated_with: :patient
  has_associated_audits

  belongs_to :patient
  belongs_to :session

  has_many :gillick_assessments
  has_many :pre_screenings
  has_many :session_statuses
  has_one :registration_status

  has_one :location, through: :session
  has_one :team, through: :session
  has_one :organisation, through: :session
  has_many :session_attendances, dependent: :destroy

  has_many :notes, -> { where(session_id: it.session_id) }, through: :patient

  has_one :latest_note,
          -> { where(session_id: it.session_id).order(created_at: :desc) },
          through: :patient,
          source: :notes

  has_many :session_notifications,
           -> { where(session_id: it.session_id) },
           through: :patient

  has_many :vaccination_records,
           -> { where(session_id: it.session_id) },
           through: :patient

  has_and_belongs_to_many :immunisation_imports

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

  scope :in_programmes,
        ->(programmes) do
          joins(:patient).merge(Patient.in_programmes(programmes))
        end

  scope :search_by_name,
        ->(name) { joins(:patient).merge(Patient.search_by_name(name)) }

  scope :search_by_year_groups,
        ->(year_groups) do
          joins(:patient).merge(Patient.search_by_year_groups(year_groups))
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

  scope :includes_programmes, -> { preload(:patient, session: :programmes) }

  scope :has_consent_status,
        ->(status, programme:) do
          where(
            Patient::ConsentStatus
              .where("patient_id = patient_sessions.patient_id")
              .where(status:, programme:)
              .arel
              .exists
          )
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

  scope :has_session_status,
        ->(status, programme:) do
          where(
            PatientSession::SessionStatus
              .where("patient_session_id = patient_sessions.id")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_triage_status,
        ->(status, programme:) do
          where(
            Patient::TriageStatus
              .where("patient_id = patient_sessions.patient_id")
              .where(status:, programme:)
              .arel
              .exists
          )
        end

  scope :has_vaccine_method,
        ->(vaccine_method, programme:) do
          where(
            Patient::TriageStatus
              .where("patient_id = patient_sessions.patient_id")
              .where(vaccine_method:, programme:)
              .arel
              .exists
          ).or(
            where(
              Patient::TriageStatus
                .where("patient_id = patient_sessions.patient_id")
                .where(status: "not_required", programme:)
                .arel
                .exists
            ).where(
              Patient::ConsentStatus
                .where("patient_id = patient_sessions.patient_id")
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

            programmes.any? do |programme|
              patient.consent_given_and_safe_to_vaccinate?(
                programme:,
                vaccine_method:
              )
            end
          end
        end

  scope :destroy_all_if_safe,
        -> do
          includes(
            :gillick_assessments,
            :session_attendances,
            :vaccination_records
          ).find_each(&:destroy_if_safe!)
        end

  def safe_to_destroy?
    vaccination_records.empty? && gillick_assessments.empty? &&
      session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def can_record_as_already_vaccinated?(programme:)
    !session.today? && patient.vaccination_status(programme:).none_yet?
  end

  def programmes = session.eligible_programmes_for(patient:)

  def session_status(programme:)
    session_statuses.find { it.programme_id == programme.id } ||
      session_statuses.build(programme:)
  end

  def todays_attendance
    if (session_date = session.session_dates.today.first)
      session_attendances.includes(:session_date).find_or_initialize_by(
        session_date:
      )
    end
  end

  def next_activity(programme:)
    return nil if patient.vaccination_status(programme:).vaccinated?

    return :record if patient.consent_given_and_safe_to_vaccinate?(programme:)

    return :triage if patient.triage_status(programme:).required?

    consent_status = patient.consent_status(programme:)

    return :consent if consent_status.no_response? || consent_status.conflicts?

    :do_not_record
  end

  def outstanding_programmes
    if registration_status.nil? || registration_status.unknown? ||
         registration_status.not_attending?
      return []
    end

    # If this patient hasn't been seen yet by a nurse for any of the programmes,
    # we don't want to show the banner.
    all_programmes_none_yet =
      programmes.all? { |programme| session_status(programme:).none_yet? }

    return [] if all_programmes_none_yet

    programmes.select do |programme|
      session_status(programme:).none_yet? &&
        patient.consent_given_and_safe_to_vaccinate?(programme:)
    end
  end
end
