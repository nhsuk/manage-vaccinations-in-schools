# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                   :bigint           not null, primary key
#  knows_consequences   :boolean          not null
#  knows_delivery       :boolean          not null
#  knows_disease        :boolean          not null
#  knows_side_effects   :boolean          not null
#  knows_vaccination    :boolean          not null
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_session_id    (patient_session_id) UNIQUE
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
FactoryBot.define do
  factory :gillick_assessment do
    assessor
    patient_session
    competent
    recorded_at { Time.current }

    trait :not_competent do
      gillick_competent { false }
      notes { "Assessed as not Gillick competent" }
    end

    trait :competent do
      gillick_competent { true }
      notes { "Assessed as Gillick competent" }
    end

    trait :draft do
      recorded_at { nil }
    end
  end
end
