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
FactoryBot.define do
  factory :triage do
    status { :ready_to_vaccinate }
    notes { nil }
    patient { create :patient }
  end
end
