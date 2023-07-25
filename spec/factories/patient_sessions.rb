# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
FactoryBot.define do
  factory :patient_session do
    patient { create :patient }
    session { create :session }

    trait :added_to_session do
      state { "added_to_session" }
    end

    trait :consent_given_triage_not_needed do
      state { "consent_given_triage_not_needed" }
      patient do
        create :patient, :consent_given_triage_not_needed, session:
      end
    end

    trait :consent_given_triage_needed do
      state { "consent_given_triage_needed" }
      patient { create :patient, :consent_given_triage_needed, session: }
    end

    trait :consent_refused do
      state { "consent_refused" }
      patient { create :patient, :consent_refused, session: }
    end

    trait :triaged_ready_to_vaccinate do
      state { "triaged_ready_to_vaccinate" }
      patient { create :patient, :triaged_ready_to_vaccinate, session: }
    end

    trait :triaged_do_not_vaccinate do
      state { "triaged_do_not_vaccinate" }
      patient { create :patient, :triaged_do_not_vaccinate, session: }
    end

    trait :triaged_kept_in_triage do
      state { "triaged_kept_in_triage" }
      patient { create :patient, :triaged_kept_in_triage, session: }
    end

    trait :unable_to_vaccinate do
      state { "unable_to_vaccinate" }
      patient { create :patient, :triaged_ready_to_vaccinate, session: }

      after :create do |patient_session|
        create :vaccination_record,
               reason: :contraindications,
               administered: false,
               patient_session:
      end
    end

    trait :vaccinated do
      state { "vaccinated" }
      patient { create :patient, :triaged_ready_to_vaccinate, session: }

      after :create do |patient_session|
        create :vaccination_record,
               administered: true,
               patient_session:
      end
    end
  end
end
