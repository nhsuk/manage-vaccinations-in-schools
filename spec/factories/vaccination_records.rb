# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                                      :bigint           not null, primary key
#  confirmation_sent_at                    :datetime
#  delivery_method                         :integer
#  delivery_site                           :integer
#  discarded_at                            :datetime
#  dose_sequence                           :integer
#  full_dose                               :boolean
#  location_name                           :string
#  nhs_immunisations_api_etag              :string
#  nhs_immunisations_api_identifier_system :string
#  nhs_immunisations_api_identifier_value  :string
#  nhs_immunisations_api_primary_source    :boolean
#  nhs_immunisations_api_sync_pending_at   :datetime
#  nhs_immunisations_api_synced_at         :datetime
#  notes                                   :text
#  notify_parents                          :boolean
#  outcome                                 :integer          not null
#  pending_changes                         :jsonb            not null
#  performed_at                            :datetime         not null
#  performed_by_family_name                :string
#  performed_by_given_name                 :string
#  performed_ods_code                      :string
#  programme_type                          :enum
#  protocol                                :integer
#  source                                  :integer          not null
#  uuid                                    :uuid             not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  batch_id                                :bigint
#  location_id                             :bigint
#  next_dose_delay_triage_id               :bigint
#  nhs_immunisations_api_id                :string
#  patient_id                              :bigint           not null
#  performed_by_user_id                    :bigint
#  programme_id                            :bigint           not null
#  session_id                              :bigint
#  supplied_by_user_id                     :bigint
#  vaccine_id                              :bigint
#
# Indexes
#
#  idx_vr_fast_lookup                                              (patient_id,programme_id,outcome) WHERE (discarded_at IS NULL)
#  index_vaccination_records_on_batch_id                           (batch_id)
#  index_vaccination_records_on_discarded_at                       (discarded_at)
#  index_vaccination_records_on_location_id                        (location_id)
#  index_vaccination_records_on_next_dose_delay_triage_id          (next_dose_delay_triage_id)
#  index_vaccination_records_on_nhs_immunisations_api_id           (nhs_immunisations_api_id) UNIQUE
#  index_vaccination_records_on_patient_id                         (patient_id)
#  index_vaccination_records_on_patient_id_and_session_id          (patient_id,session_id)
#  index_vaccination_records_on_pending_changes_not_empty          (id) WHERE (pending_changes <> '{}'::jsonb)
#  index_vaccination_records_on_performed_by_user_id               (performed_by_user_id)
#  index_vaccination_records_on_performed_ods_code_and_patient_id  (performed_ods_code,patient_id) WHERE (session_id IS NULL)
#  index_vaccination_records_on_programme_id                       (programme_id)
#  index_vaccination_records_on_session_id                         (session_id)
#  index_vaccination_records_on_supplied_by_user_id                (supplied_by_user_id)
#  index_vaccination_records_on_uuid                               (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id                         (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (next_dose_delay_triage_id => triages.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (supplied_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :vaccination_record do
    transient do
      team do
        programme.teams.includes(:organisation).first ||
          association(:team, programmes: [programme])
      end
    end

    programme { CachedProgramme.sample }

    performed_ods_code { team.organisation.ods_code }

    patient do
      association :patient,
                  school: session&.location&.school? ? session.location : nil
    end

    delivery_site { "left_arm_upper_position" }
    delivery_method { "intramuscular" }

    vaccine do
      if session
        programme.vaccines.active.sample || association(:vaccine, programme:)
      end
    end

    batch do
      if vaccine
        association(:batch, :not_expired, team:, vaccine:, strategy: :create)
      end
    end

    performed_by

    outcome { "administered" }
    performed_at { Time.current }

    dose_sequence { programme.default_dose_sequence }
    full_dose { true }
    protocol { "pgd" }

    uuid { SecureRandom.uuid }
    source { session.present? ? "service" : "historical_upload" }

    location { session&.location unless session&.generic_clinic? }
    location_name { "Unknown" if location.nil? }

    notify_parents { true }

    trait :sourced_from_nhs_immunisations_api do
      source { "nhs_immunisations_api" }
      nhs_immunisations_api_id { SecureRandom.uuid }
      nhs_immunisations_api_identifier_system { SecureRandom.uuid }
      nhs_immunisations_api_identifier_value { SecureRandom.uuid }
      nhs_immunisations_api_primary_source { true }
    end

    trait :not_administered do
      delivery_site { nil }
      delivery_method { nil }
      outcome { "not_well" }
      vaccine { nil }
      dose_sequence { nil }
      full_dose { nil }
    end

    trait :already_had do
      not_administered
      outcome { "already_had" }
    end

    trait :contraindications do
      not_administered
      outcome { "contraindications" }
    end

    trait :refused do
      not_administered
      outcome { "refused" }
    end

    trait :absent_from_session do
      not_administered
      outcome { "absent_from_session" }
    end

    trait :performed_by_not_user do
      performed_by { nil }
      performed_by_given_name { Faker::Name.first_name }
      performed_by_family_name { Faker::Name.last_name }
    end

    trait :half_dose do
      full_dose { false }
    end

    trait :discarded do
      discarded_at { Time.current }
    end

    trait :confirmation_sent do
      confirmation_sent_at { Time.current }
    end
  end
end
