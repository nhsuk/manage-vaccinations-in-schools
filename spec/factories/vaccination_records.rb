# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  delivery_method    :integer
#  delivery_site      :integer
#  dose_sequence      :integer          not null
#  exported_to_dps_at :datetime
#  notes              :text
#  reason             :integer
#  recorded_at        :datetime
#  uuid               :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_id           :bigint
#  imported_from_id   :bigint
#  patient_session_id :bigint           not null
#  user_id            :bigint
#  vaccine_id         :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id            (batch_id)
#  index_vaccination_records_on_imported_from_id    (imported_from_id)
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#  index_vaccination_records_on_user_id             (user_id)
#  index_vaccination_records_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :vaccination_record do
    transient do
      campaign { create :campaign }
      patient_attributes { {} }
      session_attributes { {} }
    end

    patient_session do
      association :patient_session,
                  campaign:,
                  patient_attributes:,
                  session_attributes:
    end
    recorded_at { "2023-06-09" }
    delivery_site { "left_arm_upper_position" }
    delivery_method { "intramuscular" }
    vaccine { patient_session.session.campaign.vaccines.first }
    batch { vaccine.batches.first }
    user { create :user }
    administered { true }
    dose_sequence { 1 }
    uuid { SecureRandom.uuid }

    trait :unrecorded do
      recorded_at { nil }
      user { nil }
    end

    trait :unadministered do
      administered { false }
      reason { "not_well" }
    end
  end
end
