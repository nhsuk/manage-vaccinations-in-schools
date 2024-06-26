# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                 :bigint           not null, primary key
#  gillick_competent  :boolean
#  notes              :text
#  recorded_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  assessor_user_id   :bigint           not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_assessor_user_id    (assessor_user_id)
#  index_gillick_assessments_on_patient_session_id  (patient_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessor_user_id => users.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#
FactoryBot.define do
  factory :gillick_assessment do
    assessor { create :user }
    patient_session { create :patient_session }
    competent

    trait :not_competent do
      gillick_competent { false }
      notes { "Assessed as not Gillick competent" }
    end

    trait :competent do
      gillick_competent { true }
      notes { "Assessed as Gillick competent" }
    end
  end
end
