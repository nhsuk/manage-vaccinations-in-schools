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
FactoryBot.define do
  factory :triage do
    status { :ready_to_vaccinate }
    notes { nil }
    patient_session { association :patient_session }
    user { association :user }

    traits_for_enum :status
  end
end
