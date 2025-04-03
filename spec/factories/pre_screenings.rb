# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                    :bigint           not null, primary key
#  feeling_well          :boolean          not null
#  knows_vaccination     :boolean          not null
#  no_allergies          :boolean          not null
#  not_already_had       :boolean          not null
#  not_pregnant          :boolean          not null
#  not_taking_medication :boolean          not null
#  notes                 :text             default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_session_id    :bigint           not null
#  performed_by_user_id  :bigint           not null
#  programme_id          :bigint           not null
#  session_date_id       :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_session_id    (patient_session_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#  index_pre_screenings_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
FactoryBot.define do
  factory :pre_screening do
    patient_session
    programme { patient_session.programmes.first }
    performed_by

    trait :allows_vaccination do
      knows_vaccination { true }
      not_already_had { true }
      feeling_well { true }
      no_allergies { true }
      not_taking_medication { true }
      not_pregnant { true }
      notes { "Fine to vaccinate" }
    end

    trait :prevents_vaccination do
      knows_vaccination { false }
      not_already_had { false }
      feeling_well { false }
      no_allergies { false }
      not_taking_medication { false }
      not_pregnant { false }
      notes { "Not safe to vaccinate" }
    end
  end
end
