# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  state              :string
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
  has_one :gillick_assessment
  has_one :draft_gillick_assessment,
          -> { draft },
          class_name: "GillickAssessment"

  has_one :campaign, through: :session
  has_many :triage
  has_many :vaccination_records
  has_many :consents,
           ->(patient) do
             Consent.submitted_for_campaign(patient.campaign).includes(:parent)
           end,
           through: :patient,
           class_name: "Consent"

  def vaccination_record
    # HACK: in future, it will be possible to have multiple vaccination records for a patient session
    vaccination_records.recorded.last
  end

  def draft_vaccination_record
    vaccination_records.draft.find_or_initialize_by(recorded_at: nil)
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

  def latest_triage
    triage.max_by(&:created_at)
  end
end
