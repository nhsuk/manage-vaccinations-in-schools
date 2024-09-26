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

      session do
        Session.find_by(team:, location:) ||
          create(:session, date: nil, team:, programme: instance, location:)
      end

      batch_count { 4 }
    end

    team { user.team || create(:team, users: [user]) }

    after(:create) do |_programme, context|
      create_list(:location, 20, :school, team: context.team)
    end

    trait :in_progress do
      after(:create) do |programme, context|
        session = context.session
        user = context.user

        session.dates.find_or_create_by!(value: Date.current)

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

    trait :in_past do
      after(:create) do |programme, context|
        session = context.session
        user = context.user

        session.dates.find_or_create_by!(value: Date.yesterday)

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

    trait :in_future do
      after(:create) do |programme, context|
        session = context.session
        user = context.user

        session.dates.find_or_create_by!(value: Date.tomorrow)

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
