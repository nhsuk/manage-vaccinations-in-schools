# frozen_string_literal: true

FactoryBot.define do
  factory :example_programme, parent: :programme do
    hpv

    transient do
      user { create(:user) }

      # this name and URN matches the data in spec/fixtures/cohort_import/valid_cohort.csv
      location do
        create(:location, :school, name: "Surrey Primary", urn: "123456", team:)
      end

      batch_count { 4 }
    end

    team { user.team || create(:team, users: [user]) }

    trait :in_progress do
      after(:create) do |programme, context|
        location = context.location
        user = context.user

        create(
          :session,
          :today,
          team: programme.team,
          programme:,
          location:
        ).tap do |session|
          patients_without_consent =
            create_list(
              :patient_session,
              4,
              programme:,
              session:,
              created_by: user
            )
          unmatched_patients = patients_without_consent.sample(2).map(&:patient)
          unmatched_patients.each do |patient|
            create(
              :consent_form,
              :recorded,
              programme:,
              first_name: patient.first_name,
              last_name: patient.last_name,
              session:
            )
          end

          create_list(
            :patient_session,
            4,
            :consent_given_triage_not_needed,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :consent_given_triage_needed,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :triaged_ready_to_vaccinate,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :consent_refused,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            2,
            :consent_conflicting,
            programme:,
            session:,
            created_by: user
          )
        end
      end
    end

    trait :in_past do
      after(:create) do |programme, context|
        location = context.location
        user = context.user

        create(
          :session,
          :completed,
          team: programme.team,
          programme:,
          location:
        ).tap do |session|
          create_list(
            :patient_session,
            4,
            :vaccinated,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :delay_vaccination,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :unable_to_vaccinate,
            programme:,
            session:,
            created_by: user
          )
        end
      end
    end

    trait :in_future do
      after(:create) do |programme, context|
        location = context.location
        user = context.user

        create(
          :session,
          :planned,
          team: programme.team,
          programme:,
          location:
        ).tap do |session|
          patients_without_consent =
            create_list(
              :patient_session,
              16,
              programme:,
              session:,
              created_by: user
            )
          unmatched_patients = patients_without_consent.sample(8).map(&:patient)
          unmatched_patients.each do |patient|
            create(
              :consent_form,
              :recorded,
              programme:,
              first_name: patient.first_name,
              last_name: patient.last_name,
              session:
            )
          end
          create_list(
            :patient_session,
            8,
            :consent_given_triage_not_needed,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            8,
            :consent_given_triage_needed,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            8,
            :consent_refused,
            programme:,
            session:,
            created_by: user
          )
          create_list(
            :patient_session,
            4,
            :consent_conflicting,
            programme:,
            session:,
            created_by: user
          )
        end
      end
    end
  end
end
