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
#  index_patient_sessions_on_patient_id                 (patient_id)
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

  include PatientSessionStatusConcern

  belongs_to :patient
  belongs_to :session

  has_one :location, through: :session
  has_one :team, through: :session
  has_one :organisation, through: :session
  has_many :session_attendances, dependent: :destroy

  has_many :gillick_assessments, -> { order(:created_at) }
  has_many :pre_screenings, -> { order(:created_at) }

  has_many :session_notifications,
           -> { where(session_id: _1.session_id) },
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

  scope :preload_for_status,
        -> do
          eager_load(:patient).preload(
            session_attendances: :session_date,
            patient: [:triages, { consents: :parent }, :vaccination_records],
            session: :programmes
          )
        end

  scope :in_programmes,
        ->(programmes) { merge(Patient.in_programmes(programmes)) }

  scope :search_by_name, ->(name) { merge(Patient.search_by_name(name)) }

  scope :search_by_year_groups,
        ->(year_groups) { merge(Patient.search_by_year_groups(year_groups)) }

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
          order("LOWER(patients.family_name)", "LOWER(patients.given_name)")
        end

  def safe_to_destroy?
    programmes.none? { session_outcome.all[it].any? } &&
      gillick_assessments.empty? && session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def can_record_as_already_vaccinated?(programme:)
    !session.today? && patient.programme_outcome.none?(programme)
  end

  def programmes
    session.programmes.select { it.year_groups.include?(patient.year_group) }
  end

  def gillick_assessment(programme)
    gillick_assessments
      .select { it.programme_id == programme.id }
      .max_by(&:created_at)
  end

  def register_outcome
    @register_outcome ||= PatientSession::RegisterOutcome.new(self)
  end

  def session_outcome
    @session_outcome ||= PatientSession::SessionOutcome.new(self)
  end

  def ready_for_vaccinator?(programme: nil)
    return false if register_outcome.unknown? || register_outcome.not_attending?

    programmes_to_check = programme ? [programme] : programmes

    programmes_to_check.any? do
      patient.consent_given_and_safe_to_vaccinate?(programme: it) &&
        (
          session_outcome.latest[it].nil? ||
            session_outcome.latest[it].retryable_reason?
        )
    end
  end
end
