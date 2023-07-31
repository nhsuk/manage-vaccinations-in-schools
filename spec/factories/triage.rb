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
FactoryBot.define do
  factory :triage do
    status { :ready_to_vaccinate }
    notes { nil }
    patient { create :patient }
  end
end
