# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                       :bigint           not null, primary key
#  confirmation_sent_at     :datetime
#  delivery_method          :integer
#  delivery_site            :integer
#  discarded_at             :datetime
#  dose_sequence            :integer          not null
#  location_name            :string
#  notes                    :text
#  outcome                  :integer          not null
#  pending_changes          :jsonb            not null
#  performed_at             :datetime         not null
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  patient_session_id       :bigint           not null
#  performed_by_user_id     :bigint
#  programme_id             :bigint           not null
#  vaccine_id               :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_discarded_at          (discarded_at)
#  index_vaccination_records_on_patient_session_id    (patient_session_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_programme_id          (programme_id)
#  index_vaccination_records_on_uuid                  (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :vaccination_record do
    transient do
      session { association :session, programme: }
      patient do
        association :patient,
                    school: session.location.school? ? session.location : nil
      end
    end

    programme
    patient_session do
      association :patient_session,
                  programme:,
                  patient:,
                  session:,
                  strategy: :create
    end

    delivery_site { "left_arm_upper_position" }
    delivery_method { "intramuscular" }
    vaccine { programme.vaccines.active.first }
    batch do
      if vaccine
        association :batch,
                    organisation: patient_session.organisation,
                    vaccine:,
                    strategy: :create
      end
    end

    performed_by

    outcome { "administered" }
    performed_at { Time.current }

    dose_sequence { 1 }
    uuid { SecureRandom.uuid }

    trait :not_administered do
      delivery_site { nil }
      delivery_method { nil }
      outcome { "not_well" }
      vaccine { nil }
    end

    trait :performed_by_not_user do
      performed_by { nil }
      performed_by_given_name { Faker::Name.first_name }
      performed_by_family_name { Faker::Name.last_name }
    end

    trait :discarded do
      discarded_at { Time.current }
    end

    trait :confirmation_sent do
      confirmation_sent_at { Time.current }
    end
  end
end
