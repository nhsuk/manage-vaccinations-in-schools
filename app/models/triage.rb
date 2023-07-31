# == Schema Information
#
# Table name: triage
#
#  id          :bigint           not null, primary key
#  notes       :text
#  status      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint
#  patient_id  :bigint
#
# Indexes
#
#  index_triage_on_campaign_id  (campaign_id)
#  index_triage_on_patient_id   (patient_id)
#
class Triage < ApplicationRecord
  audited

  belongs_to :campaign
  belongs_to :patient

  enum :status, %i[ready_to_vaccinate do_not_vaccinate needs_follow_up]

  validates :status,
    presence: true,
    inclusion: { in: statuses.keys },
    on: :edit_questions

  def triage_complete?
    ready_to_vaccinate? || do_not_vaccinate?
  end
end
