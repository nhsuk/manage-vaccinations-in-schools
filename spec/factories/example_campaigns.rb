# frozen_string_literal: true

FactoryBot.define do
  factory :example_campaign, parent: :campaign do
    transient do
      user { create(:user) }
      # this name and URN matches the data in spec/fixtures/cohort_list/valid_cohort.csv
      location { create(:location, name: "Surrey Primary", urn: "123456") }
    end

    team { user.team || create(:team, users: [user]) }
  end

  trait :in_progress do
    after(:create) do |campaign, context|
      location = context.location
      user = context.user

      create(:session, :in_progress, campaign:, location:).tap do |session|
        patients_without_consent =
          create_list(:patient_session, 4, session:, user:)
        unmatched_patients = patients_without_consent.sample(2).map(&:patient)
        unmatched_patients.each do |patient|
          create(
            :consent_form,
            :recorded,
            first_name: patient.first_name,
            last_name: patient.last_name,
            session:
          )
        end

        create_list(
          :patient_session,
          4,
          :consent_given_triage_not_needed,
          session:,
          user:
        )
        create_list(
          :patient_session,
          4,
          :consent_given_triage_needed,
          session:,
          user:
        )
        create_list(
          :patient_session,
          4,
          :triaged_ready_to_vaccinate,
          session:,
          user:
        )
        create_list(:patient_session, 4, :consent_refused, session:, user:)
        create_list(:patient_session, 2, :consent_conflicting, session:, user:)
      end
    end
  end

  trait :in_past do
    after(:create) do |campaign, context|
      location = context.location
      user = context.user

      create(:session, :in_past, campaign:, location:).tap do |session|
        create_list(:patient_session, 4, :vaccinated, session:, user:)
        create_list(:patient_session, 4, :delay_vaccination, session:, user:)
        create_list(:patient_session, 4, :unable_to_vaccinate, session:, user:)
      end
    end
  end

  trait :in_future do
    after(:create) do |campaign, context|
      location = context.location
      user = context.user

      create(:session, :in_future, campaign:, location:).tap do |session|
        patients_without_consent =
          create_list(:patient_session, 16, session:, user:)
        unmatched_patients = patients_without_consent.sample(8).map(&:patient)
        unmatched_patients.each do |patient|
          create(
            :consent_form,
            :recorded,
            first_name: patient.first_name,
            last_name: patient.last_name,
            session:
          )
        end
        create_list(
          :patient_session,
          8,
          :consent_given_triage_not_needed,
          session:,
          user:
        )
        create_list(
          :patient_session,
          8,
          :consent_given_triage_needed,
          session:,
          user:
        )
        create_list(:patient_session, 8, :consent_refused, session:, user:)
        create_list(:patient_session, 4, :consent_conflicting, session:, user:)
      end
    end
  end
end
