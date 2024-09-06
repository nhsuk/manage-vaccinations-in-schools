# frozen_string_literal: true

FactoryBot.define do
  factory :example_programme, parent: :programme do
    hpv

    transient do
      user { create(:user) }
      # this name and URN matches the data in spec/fixtures/cohort_list/valid_cohort.csv
      location do
        create(:location, :school, name: "Surrey Primary", urn: "123456")
      end
      batch_count { 4 }
    end

    team { user.team || create(:team, users: [user]) }
  end

  trait :in_progress do
    after(:create) do |programme, context|
      location = context.location
      user = context.user

      create(:session, :in_progress, programme:, location:).tap do |session|
        patients_without_consent =
          create_list(:patient_session, 4, session:, created_by: user)
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
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :consent_given_triage_needed,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :triaged_ready_to_vaccinate,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :consent_refused,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          2,
          :consent_conflicting,
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

      create(:session, :in_past, programme:, location:).tap do |session|
        create_list(
          :patient_session,
          4,
          :vaccinated,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :delay_vaccination,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :unable_to_vaccinate,
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

      create(:session, :in_future, programme:, location:).tap do |session|
        patients_without_consent =
          create_list(:patient_session, 16, session:, created_by: user)
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
          created_by: user
        )
        create_list(
          :patient_session,
          8,
          :consent_given_triage_needed,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          8,
          :consent_refused,
          session:,
          created_by: user
        )
        create_list(
          :patient_session,
          4,
          :consent_conflicting,
          session:,
          created_by: user
        )
      end
    end
  end
end
