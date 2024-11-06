# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  patient_id          :bigint           not null
#  proposed_session_id :bigint
#  session_id          :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_proposed_session_id        (proposed_session_id)
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (proposed_session_id => sessions.id)
#
FactoryBot.define do
  factory :patient_session do
    transient do
      programme { association :programme }
      organisation { session.organisation }
      user { association :user, organisations: [organisation] }
    end

    session { association :session, programme: }
    patient { association :patient, organisation:, school: session.location }

    trait :added_to_session

    trait :consent_given_triage_not_needed do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :consent_given_triage_needed do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :consent_refused do
      patient do
        association :patient,
                    :consent_refused,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :consent_refused_with_notes do
      patient do
        association :patient,
                    :consent_refused_with_notes,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :consent_conflicting do
      patient do
        association :patient,
                    :consent_conflicting,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :triaged_ready_to_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_ready_to_vaccinate,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :triaged_do_not_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_do_not_vaccinate,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :triaged_kept_in_triage do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_needs_follow_up,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :delay_vaccination do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_delay_vaccination,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          :not_administered,
          patient_session:,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          reason: :absent_from_school
        )
      end
    end

    trait :did_not_need_triage do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end
    end

    trait :unable_to_vaccinate do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_ready_to_vaccinate,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          :not_administered,
          patient_session:,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          reason: :already_had
        )
      end
    end

    trait :vaccinated do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_ready_to_vaccinate,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school: session.location
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          patient_session:,
          programme: evaluator.programme,
          performed_by: evaluator.user
        )
      end
    end

    trait :session_in_progress do
      session { association :session, :today, programme: }
    end

    trait :not_gillick_competent do
      after(:create) do |patient_session, _evaluator|
        create(:gillick_assessment, :not_competent, patient_session:)
      end
    end

    trait :gillick_competent do
      after(:create) do |patient_session, _evaluator|
        create(:gillick_assessment, :competent, patient_session:)
      end
    end
  end
end
