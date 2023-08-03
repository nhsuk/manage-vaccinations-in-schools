# == Schema Information
#
# Table name: triage
#
#  id                 :bigint           not null, primary key
#  notes              :text
#  status             :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  patient_session_id :bigint
#
# Indexes
#
#  index_triage_on_patient_session_id  (patient_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#
class Triage < ApplicationRecord
  audited associated_with: :patient_session

  belongs_to :patient_session
  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session
  has_one :campaign, through: :session

  enum :status, %i[ready_to_vaccinate do_not_vaccinate needs_follow_up]

  validates :status,
            presence: true,
            inclusion: {
              in: statuses.keys
            },
            on: %i[edit_questions consent]

  def triage_complete?
    ready_to_vaccinate? || do_not_vaccinate?
  end
end
