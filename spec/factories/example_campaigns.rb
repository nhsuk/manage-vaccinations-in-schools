FactoryBot.define do
  factory :example_campaign, parent: :campaign do
    transient do
      user { create(:user) }
      location { create(:location, team:) }
    end

    team { create(:team, users: [user]) }
  end

  trait :in_progress do
    after(:create) do |campaign, context|
      location = context.location

      create(:session, :in_progress, campaign:, location:).tap do |session|
        patients_without_consent = create_list(:patient_session, 4, session:)
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
          session:
        )
        create_list(:patient_session, 4, :consent_given_triage_needed, session:)
        create_list(
          :patient_session,
          4,
          :triaged_ready_to_vaccinate,
          session:,
          user: context.user
        )
        create_list(:patient_session, 4, :consent_refused, session:)
        create_list(:patient_session, 2, :consent_conflicting, session:)
      end
    end
  end

  trait :in_past do
    after(:create) do |campaign, context|
      location = context.location

      create(:session, :in_past, campaign:, location:).tap do |session|
        create_list(
          :patient_session,
          4,
          :vaccinated,
          session:,
          user: context.user
        )
        create_list(
          :patient_session,
          4,
          :delay_vaccination,
          session:,
          user: context.user
        )
        create_list(
          :patient_session,
          4,
          :unable_to_vaccinate,
          session:,
          user: context.user
        )
      end
    end
  end
end
