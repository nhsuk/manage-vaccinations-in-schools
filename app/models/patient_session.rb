# == Schema Information
#
# Table name: patient_sessions
#
#  id                                  :bigint           not null, primary key
#  gillick_competence_notes            :text
#  gillick_competent                   :boolean
#  state                               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  gillick_competence_assessor_user_id :bigint
#  patient_id                          :bigint           not null
#  session_id                          :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_gillick_competence_assessor_user_id  (gillick_competence_assessor_user_id)
#  index_patient_sessions_on_patient_id_and_session_id            (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id            (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (gillick_competence_assessor_user_id => users.id)
#

class PatientSession < ApplicationRecord
  audited
  has_associated_audits

  include PatientSessionStateConcern

  belongs_to :patient
  belongs_to :session
  belongs_to :gillick_competence_assessor,
             class_name: "User",
             optional: true,
             foreign_key: :gillick_competence_assessor_user_id

  has_one :campaign, through: :session
  has_many :triage, -> { order(:updated_at) }
  has_many :vaccination_records
  has_many :consents,
           ->(patient) { Consent.submitted_for_campaign(patient.campaign) },
           through: :patient,
           class_name: "Consent"

  validates :gillick_competent,
            inclusion: {
              in: [true, false]
            },
            on: :edit_gillick
  validates :gillick_competence_notes, presence: true, on: :edit_gillick
  validates :gillick_competence_assessor, presence: true, on: :edit_gillick

  encrypts :gillick_competence_notes

  validates :gillick_competence_notes, length: { maximum: 1000 }

  def vaccination_record
    vaccination_records.where.not(recorded_at: nil).last
  end

  def able_to_vaccinate?
    !unable_to_vaccinate? && !unable_to_vaccinate_not_assessed? &&
      !unable_to_vaccinate_not_gillick_competent?
  end

  def latest_consents
    consents
      .group_by(&:name)
      .map { |_, consents| consents.max_by(&:recorded_at) }
  end
end
