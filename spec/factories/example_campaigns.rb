FactoryBot.define do
  factory :example_in_progress_campaign, parent: :campaign do
    transient do
      user { raise "create(:user)" }
      location { create(:location, team:) }
    end

    team { create(:team, users: [user]) }

    after(:create) do |campaign, context|
      location = context.location

      create(:session, :in_progress, campaign:, location:).tap do |session|
        patients_without_consent = create_list(:patient_session, 8, session:)
        unmatched_patients = patients_without_consent.sample(4).map(&:patient)
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
end
