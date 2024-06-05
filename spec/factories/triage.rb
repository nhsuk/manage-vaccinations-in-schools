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
#  user_id            :bigint
#
# Indexes
#
#  index_triage_on_patient_session_id  (patient_session_id)
#  index_triage_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :triage do
    status { :ready_to_vaccinate }
    notes { nil }
    patient_session { create :patient_session }
    user { create :user }

    trait :vaccinate do
      status { :ready_to_vaccinate }
    end

    trait :kept_in_triage do
      status { :needs_follow_up }
    end

    trait :delay_vaccination do
      status { :delay_vaccination }
    end

    trait :do_not_vaccinate do
      status { :do_not_vaccinate }
    end
  end
end
