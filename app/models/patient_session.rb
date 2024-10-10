# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  patient_id         :bigint           not null
#  session_id         :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_created_by_user_id         (created_by_user_id)
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#

class PatientSession < ApplicationRecord
  audited
  has_associated_audits

  include PatientSessionStateConcern

  belongs_to :patient
  belongs_to :session
  belongs_to :created_by,
             class_name: "User",
             optional: true,
             foreign_key: :created_by_user_id

  has_one :team, through: :session
  has_many :programmes, through: :session

  has_one :gillick_assessment, -> { recorded }
  has_one :draft_gillick_assessment,
          -> { draft },
          class_name: "GillickAssessment"

  has_many :triages, -> { order(:updated_at) }
  has_one :latest_triage, -> { order(created_at: :desc) }, class_name: "Triage"

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
           ->(patient_session) do
             recorded.where(programme: patient_session.programmes).includes(
               :parent
             )
           end,
           through: :patient,
           class_name: "Consent"

  has_and_belongs_to_many :immunisation_imports

  scope :reminder_not_sent,
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

  def draft_vaccination_record
    # HACK: this code will need to be revisited in future as it only really works for HPV, where we only have one
    # vaccine. It is likely to fail for the Doubles programme as that has 2 vaccines. It is also likely to fail for
    # the flu programme for the SAIS teams that offer both nasal and injectable vaccines.

    programme = programmes.first

    draft_vaccination_records.create_with(
      programme:,
      vaccine: programme.vaccines.first
    ).find_or_initialize_by(recorded_at: nil)
  end

  def gillick_competent?
    gillick_assessment&.gillick_competent?
  end

  def able_to_vaccinate?
    !unable_to_vaccinate? && !unable_to_vaccinate_not_gillick_competent?
  end

  def latest_consents
    consents
      .group_by(&:name)
      .map { |_, consents| consents.max_by(&:recorded_at) }
  end

  def consents_to_send_communication
    latest_consents.select(&:response_given?).reject(&:via_self_consent?)
  end
end
