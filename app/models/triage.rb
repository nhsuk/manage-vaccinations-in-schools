# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  notes                :text
#  status               :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint
#  performed_by_user_id :bigint
#
# Indexes
#
#  index_triage_on_patient_session_id    (patient_session_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class Triage < ApplicationRecord
  audited associated_with: :patient_session

  belongs_to :patient_session
  belongs_to :user
  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session
  has_one :campaign, through: :session

  enum :status,
       %i[
         ready_to_vaccinate
         do_not_vaccinate
         needs_follow_up
         delay_vaccination
       ],
       validate: true

  encrypts :notes

  validates :notes, length: { maximum: 1000 }

  def triage_complete?
    ready_to_vaccinate? || do_not_vaccinate?
  end
end
