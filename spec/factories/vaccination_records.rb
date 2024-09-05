# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                       :bigint           not null, primary key
#  administered_at          :datetime
#  delivery_method          :integer
#  delivery_site            :integer
#  dose_sequence            :integer          not null
#  notes                    :text
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  reason                   :integer
#  recorded_at              :datetime
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  imported_from_id         :bigint
#  patient_session_id       :bigint           not null
#  performed_by_user_id     :bigint
#  vaccine_id               :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_imported_from_id      (imported_from_id)
#  index_vaccination_records_on_patient_session_id    (patient_session_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :vaccination_record do
    transient do
      campaign { association :campaign, :active }
      session { association :session, campaign: }
      patient { association :patient }
    end

    patient_session { association :patient_session, patient:, session: }

    recorded_at { "2023-06-09" }
    delivery_site { "left_arm_upper_position" }
    delivery_method { "intramuscular" }
    vaccine { patient_session.session.campaign.vaccines.first }
    batch { vaccine.batches.first }

    performed_by { association :user }

    administered_at do
      Faker::Time.between(
        from: patient_session.session.campaign.start_date,
        to: patient_session.session.campaign.end_date
      )
    end

    dose_sequence { 1 }
    uuid { SecureRandom.uuid }

    trait :not_administered do
      administered_at { nil }
      reason { "not_well" }
    end

    trait :not_recorded do
      recorded_at { nil }
      performed_by { nil }
    end

    trait :performed_by_not_user do
      performed_by { nil }
      performed_by_given_name { Faker::Name.first_name }
      performed_by_family_name { Faker::Name.last_name }
    end
  end
end
