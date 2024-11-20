# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  patient_id          :bigint           not null
#  proposed_session_id :bigint
#  session_id          :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_proposed_session_id        (proposed_session_id)
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (proposed_session_id => sessions.id)
#

class PatientSession < ApplicationRecord
  audited

  include PatientSessionStateConcern

  belongs_to :patient
  belongs_to :session
  belongs_to :proposed_session, class_name: "Session", optional: true

  has_one :location, through: :session
  has_one :team, through: :session
  has_one :organisation, through: :session
  has_many :programmes, through: :session
  has_many :session_attendances, dependent: :destroy

  has_many :gillick_assessments, -> { order(:created_at) }
  has_many :vaccination_records, -> { kept }

  # TODO: Only fetch consents and triages for the relevant programme.
  has_many :consents, -> { eager_load(:parent) }, through: :patient
  has_many :triages, through: :patient

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

  scope :pending_transfer, -> { where.not(proposed_session_id: nil) }

  scope :preload_for_state,
        -> do
          preload(
            :consents,
            :gillick_assessments,
            :triages,
            :vaccination_records,
            :session_attendances
          )
        end

  scope :order_by_name,
        -> do
          order("LOWER(patients.given_name)", "LOWER(patients.family_name)")
        end

  delegate :send_notifications?, to: :patient
  delegate :gillick_competent?, to: :latest_gillick_assessment, allow_nil: true

  def able_to_vaccinate?
    !unable_to_vaccinate?
  end

  def safe_to_destroy?
    vaccination_records.empty? && gillick_assessments.empty? &&
      session_attendances.none?(&:attending?)
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def latest_consents
    @latest_consents ||=
      consents
        .select(&:not_invalidated?)
        .select { _1.response_given? || _1.response_refused? }
        .group_by(&:name)
        .map { |_, consents| consents.max_by(&:created_at) }
  end

  def latest_gillick_assessment
    @latest_gillick_assessment = gillick_assessments.max_by(&:updated_at)
  end

  def latest_triage
    @latest_triage ||= triages.not_invalidated.max_by(&:updated_at)
  end

  def latest_vaccination_record
    @latest_vaccination_record ||= vaccination_records.max_by(&:created_at)
  end

  def pending_transfer?
    proposed_session_id.present?
  end

  def confirm_transfer!
    return unless pending_transfer?

    PatientSession.transaction do
      PatientSession.find_or_create_by!(patient:, session: proposed_session)

      school = proposed_session.location
      school = nil if school.generic_clinic?
      patient.update!(school:)

      safe_to_destroy? ? destroy! : update!(proposed_session: nil)
    end
  end

  def ignore_transfer!
    update!(proposed_session: nil)
  end

  def current_attendance
    session_attendances.joins(:session_date).find_by(
      session_date: {
        value: Date.current
      }
    )
  end

  def attending_today?
    current_attendance&.attending?
  end
end
