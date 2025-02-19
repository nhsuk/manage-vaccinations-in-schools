# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id                 (patient_id)
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id                 (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#
FactoryBot.define do
  factory :patient_session do
    transient do
      programme { association :programme }
      organisation { session.organisation }
      user { association :user, organisation: }
      year_group { nil }
      school { session.location.school? ? session.location : nil }
      home_educated { school.present? ? nil : false }
      location_name do
        organisation.community_clinics.sample.name if session.location.clinic?
      end
    end

    session { association :session, programme: }
    patient do
      association :patient, organisation:, school:, home_educated:, year_group:
    end

    trait :in_attendance do
      session_attendances do
        [association(:session_attendance, :present, patient_session: instance)]
      end
    end

    trait :added_to_session

    trait :consent_given_triage_not_needed do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_given_triage_needed do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_refused do
      patient do
        association :patient,
                    :consent_refused,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_refused_with_notes do
      patient do
        association :patient,
                    :consent_refused_with_notes,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_not_provided do
      patient do
        association :patient,
                    :consent_not_provided,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_conflicting do
      patient do
        association :patient,
                    :consent_conflicting,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
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
                    school:,
                    home_educated:,
                    year_group:
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
                    school:,
                    home_educated:,
                    year_group:
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
                    school:,
                    home_educated:,
                    year_group:
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
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          :not_administered,
          patient: patient_session.patient,
          session: patient_session.session,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          location_name: evaluator.location_name,
          outcome: :absent_from_school
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
                    school:,
                    home_educated:,
                    year_group:
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
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          :not_administered,
          patient: patient_session.patient,
          session: patient_session.session,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          location_name: evaluator.location_name,
          outcome: :already_had
        )
      end
    end

    trait :unable_to_vaccinate_and_had_no_triage do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programme:,
                    organisation:,
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          :not_administered,
          patient: patient_session.patient,
          session: patient_session.session,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          outcome: :already_had
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
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        create(
          :vaccination_record,
          patient: patient_session.patient,
          session: patient_session.session,
          programme: evaluator.programme,
          performed_by: evaluator.user,
          location_name: evaluator.location_name
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
