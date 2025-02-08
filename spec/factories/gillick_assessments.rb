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
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_session_id    (patient_session_id)
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#  index_gillick_assessments_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :gillick_assessment do
    patient_session
    programme { patient_session.session.programmes.first }

    performed_by

    trait :not_competent do
      knows_consequences { false }
      knows_delivery { false }
      knows_disease { false }
      knows_side_effects { false }
      knows_vaccination { false }
      notes { "Assessed as not Gillick competent" }
    end

    trait :competent do
      knows_consequences { true }
      knows_delivery { true }
      knows_disease { true }
      knows_side_effects { true }
      knows_vaccination { true }
      notes { "Assessed as Gillick competent" }
    end
  end
end
