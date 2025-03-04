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
  audited

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
            :session_attendances,
            patient: [:triages, { consents: :parent }, :vaccination_records],
            session: :programmes
          )
        end

  scope :in_programmes,
        ->(programmes) { merge(Patient.in_programmes(programmes)) }

  scope :search_by_name, ->(name) { merge(Patient.search_by_name(name)) }

  scope :search_by_year_groups,
        ->(year_groups) { merge(Patient.search_by_year_groups(year_groups)) }

  scope :search_by_date_of_birth,
        ->(date_of_birth) do
          merge(Patient.search_by_date_of_birth(date_of_birth))
        end

  scope :search_by_nhs_number,
        ->(nhs_number) { merge(Patient.search_by_nhs_number(nhs_number)) }

  scope :order_by_name,
        -> do
          order("LOWER(patients.family_name)", "LOWER(patients.given_name)")
        end

  delegate :send_notifications?, to: :patient

  def safe_to_destroy?
    programmes.none? { |programme| record.all(programme:).any? } &&
      gillick_assessments.empty? && session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def can_record_as_already_vaccinated?(programme:)
    !session.today? && !vaccinated?(programme:) &&
      !unable_to_vaccinate?(programme:)
  end

  def programmes
    session.programmes.select { it.year_groups.include?(patient.year_group) }
  end

  def consent
    @consent ||= PatientSession::Consent.new(self)
  end

  def triage
    @triage ||= PatientSession::Triage.new(self)
  end

  def register
    @register ||= PatientSession::Register.new(self)
  end

  def record
    @record ||= PatientSession::Record.new(self)
  end

  def outcome
    @outcome ||= PatientSession::Outcome.new(self)
  end

  # TODO: Replace these two with objects like the above.

  def gillick_assessment(programme:)
    gillick_assessments.select { it.programme_id == programme.id }.last
  end
end
