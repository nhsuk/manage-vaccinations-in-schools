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
  has_many :programmes, through: :session

  has_many :gillick_assessments, -> { recorded }
  has_many :draft_gillick_assessments,
           -> { draft },
           class_name: "GillickAssessment"
  has_one :latest_gillick_assessment,
          -> { recorded.order(created_at: :desc) },
          class_name: "GillickAssessment"

  has_many :vaccination_records,
           -> { recorded },
           class_name: "VaccinationRecord"
  has_many :draft_vaccination_records,
           -> { draft },
           class_name: "VaccinationRecord"
  has_one :latest_vaccination_record,
          -> { recorded.order(created_at: :desc) },
          class_name: "VaccinationRecord"

  has_many :consents,
           -> { recorded.where(programme: _1.programmes).includes(:parent) },
           through: :patient,
           class_name: "Consent"

  has_many :triages,
           -> { where(programme: _1.programmes).order(:updated_at) },
           through: :patient,
           class_name: "Triage"

  has_many :session_notifications,
           -> { where(session_id: _1.session_id) },
           through: :patient,
           class_name: "SessionNotification"

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

  delegate :send_notifications?, to: :patient

  def draft_vaccination_record
    # HACK: this code will need to be revisited in future as it only really
    # works for HPV, where we only have one vaccine. It is likely to fail for
    # the Doubles programme as that has 2 vaccines. It is also likely to fail
    # for the flu programme for the SAIS teams that offer both nasal and
    # injectable vaccines.

    programme = programmes.first
    vaccine = programme.vaccines.active.first

    draft_vaccination_records.create_with(
      programme:,
      vaccine:
    ).find_or_initialize_by(recorded_at: nil)
  end

  def draft_gillick_assessment
    draft_gillick_assessments.find_or_initialize_by(recorded_at: nil)
  end

  def gillick_competent?
    latest_gillick_assessment&.gillick_competent?
  end

  def able_to_vaccinate?
    !unable_to_vaccinate? && !unable_to_vaccinate_not_gillick_competent?
  end

  def safe_to_destroy?
    vaccination_records.empty? && gillick_assessments.empty?
  end

  def destroy_if_safe!
    destroy! if safe_to_destroy?
  end

  def latest_consents
    consents
      .group_by(&:name)
      .map { |_, consents| consents.max_by(&:recorded_at) }
  end

  def latest_triage
    triages.max_by(&:updated_at)
  end

  def consents_to_send_communication
    latest_consents.select(&:response_given?).reject(&:via_self_consent?)
  end

  def pending_transfer?
    proposed_session_id.present?
  end

  def confirm_transfer!
    return unless pending_transfer?

    PatientSession.transaction do
      PatientSession.create!(patient:, session: proposed_session)

      school = proposed_session.location
      school = nil if school.generic_clinic?
      patient.update!(school:)

      safe_to_destroy? ? destroy! : update!(proposed_session: nil)
    end
  end

  def ignore_transfer!
    update!(proposed_session: nil)
  end
end
