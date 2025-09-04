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
      team { session.team }
      programmes { [association(:programme)] }
      user { association :user, team: }
      year_group do
        session.programmes.flat_map(&:default_year_groups).sort.uniq.first
      end
      school { session.location.school? ? session.location : nil }
      home_educated { school.present? ? nil : false }
      location_name do
        team.community_clinics.sample.name if session.location.clinic?
      end
    end

    session { association :session, programmes: }

    patient do
      association :patient, team:, school:, home_educated:, year_group:
    end

    trait :unknown_attendance do
      after(:create) do |patient_session|
        create(
          :patient_registration_status,
          patient: patient_session.patient,
          session: patient_session.session
        )
      end
    end

    trait :in_attendance do
      after(:create) do |patient_session|
        create(
          :attendance_record,
          :present,
          patient: patient_session.patient,
          session: patient_session.session
        )
        create(
          :patient_registration_status,
          :attending,
          patient: patient_session.patient,
          session: patient_session.session
        )
      end
    end

    trait :added_to_session

    trait :consent_no_response do
      patient do
        association :patient,
                    :consent_no_response,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_given_triage_not_needed do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_given_injection_only_triage_needed do
      patient do
        association :patient,
                    :consent_given_injection_only_triage_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :consent_given_nasal_only_triage_needed do
      patient do
        association :patient,
                    :consent_given_nasal_only_triage_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :partially_vaccinated_triage_needed do
      patient do
        association :patient,
                    :partially_vaccinated_triage_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end
    end

    trait :did_not_need_triage do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
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
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        patient_session.session.programmes.each do |programme|
          create(
            :patient_vaccination_status,
            patient: patient_session.patient,
            programme:
          )
          vaccination_record =
            create(
              :vaccination_record,
              :not_administered,
              patient: patient_session.patient,
              session: patient_session.session,
              programme:,
              performed_by: evaluator.user,
              location_name: evaluator.location_name,
              outcome: :not_well
            )
          vaccination_record.notify_parents =
            VaccinationNotificationCriteria.call(vaccination_record:)
        end
      end
    end

    trait :unable_to_vaccinate_and_had_no_triage do
      patient do
        association :patient,
                    :consent_given_triage_not_needed,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        patient_session.session.programmes.each do |programme|
          create(
            :patient_vaccination_status,
            patient: patient_session.patient,
            programme:
          )
          vaccination_record =
            create(
              :vaccination_record,
              :not_administered,
              patient: patient_session.patient,
              session: patient_session.session,
              programme:,
              performed_by: evaluator.user,
              outcome: :not_well
            )
          vaccination_record.notify_parents =
            VaccinationNotificationCriteria.call(vaccination_record:)
        end
      end
    end

    trait :vaccinated do
      patient do
        association :patient,
                    :consent_given_triage_needed,
                    :triage_ready_to_vaccinate,
                    performed_by: user,
                    programmes: session.programmes,
                    team:,
                    school:,
                    home_educated:,
                    year_group:
      end

      after(:create) do |patient_session, evaluator|
        patient_session.session.programmes.each do |programme|
          create(
            :patient_vaccination_status,
            :vaccinated,
            patient: patient_session.patient,
            programme:
          )
          vaccination_record =
            create(
              :vaccination_record,
              patient: patient_session.patient,
              session: patient_session.session,
              programme:,
              performed_by: evaluator.user,
              location_name: evaluator.location_name
            )
          vaccination_record.notify_parents =
            VaccinationNotificationCriteria.call(vaccination_record:)
        end
      end
    end
  end
end
