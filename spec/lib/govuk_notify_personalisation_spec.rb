# frozen_string_literal: true

describe GovukNotifyPersonalisation do
  subject(:personalisation) do
    described_class.call(
      patient:,
      session:,
      consent:,
      consent_form:,
      programme:,
      vaccination_record:
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:organisation) do
    create(
      :organisation,
      name: "Organisation",
      email: "organisation@example.com",
      phone: "01234 567890",
      programmes: [programme]
    )
  end

  let(:patient) do
    create(
      :patient,
      given_name: "John",
      family_name: "Smith",
      date_of_birth: Date.new(2012, 2, 1),
      year_group: 8
    )
  end
  let(:location) { create(:school, name: "Hogwarts") }
  let(:session) do
    create(
      :session,
      location:,
      organisation:,
      programme:,
      date: Date.new(2026, 1, 1)
    )
  end
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:vaccination_record) { nil }

  it do
    expect(personalisation).to eq(
      {
        catch_up: "no",
        consent_deadline: "Wednesday 31 December",
        consent_link:
          "http://localhost:4000/consents/#{session.slug}/hpv/start",
        full_and_preferred_patient_name: "John Smith",
        location_name: "Hogwarts",
        next_session_date: "Thursday 1 January",
        next_session_dates: "Thursday 1 January",
        next_session_dates_or: "Thursday 1 January",
        not_catch_up: "yes",
        organisation_privacy_notice_url: "https://example.com/privacy-notice",
        organisation_privacy_policy_url: "https://example.com/privacy-policy",
        patient_date_of_birth: "1 February 2012",
        programme_name: "HPV",
        short_patient_name: "John",
        short_patient_name_apos: "John’s",
        subsequent_session_dates_offered_message: "",
        team_email: "organisation@example.com",
        team_name: "Organisation",
        team_phone: "01234 567890",
        vaccination: "HPV vaccination"
      }
    )
  end

  context "when patient is in Year 9" do
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        date_of_birth: Date.current - 14.years
      )
    end

    it { should include(catch_up: "yes", not_catch_up: "no") }
  end

  context "with multiple dates" do
    before { session.session_dates.create!(value: Date.new(2026, 1, 2)) }

    it do
      expect(personalisation).to match(
        hash_including(
          consent_deadline: "Wednesday 31 December",
          next_session_date: "Thursday 1 January",
          next_session_dates: "Thursday 1 January and Friday 2 January",
          next_session_dates_or: "Thursday 1 January or Friday 2 January",
          subsequent_session_dates_offered_message:
            "If they’re not seen, they’ll be offered the vaccination on Friday 2 January."
        )
      )
    end

    context "when today is the first date" do
      around { |example| travel_to(Date.new(2026, 1, 1)) { example.run } }

      it do
        expect(personalisation).to match(
          hash_including(consent_deadline: "Thursday 1 January")
        )
      end
    end
  end

  context "with a consent" do
    let(:consent) do
      create(:consent, :refused, programme:, created_at: Date.new(2024, 1, 1))
    end

    it do
      expect(personalisation).to match(
        hash_including(
          reason_for_refusal: "of personal choice",
          survey_deadline_date: "8 January 2024"
        )
      )
    end
  end

  context "with a consent form" do
    let(:consent_form) do
      create(
        :consent_form,
        :refused,
        session:,
        recorded_at: Date.new(2024, 1, 1)
      )
    end

    it do
      expect(personalisation).to include(
        reason_for_refusal: "of personal choice",
        survey_deadline_date: "8 January 2024",
        location_name: "Hogwarts"
      )
    end

    context "where the school is different" do
      let(:session) { nil }
      let(:school) { create(:school, name: "Waterloo Road", organisation:) }

      let(:consent_form) do
        create(
          :consent_form,
          :given,
          :recorded,
          session: create(:session, location:, programme:, organisation:),
          school_confirmed: false,
          school:
        )
      end

      before { create(:session, location: school, programme:, organisation:) }

      it { should include(location_name: "Waterloo Road") }
    end
  end

  context "with a vaccination record" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        performed_at: Date.new(2024, 1, 1)
      )
    end

    it do
      expect(personalisation).to match(
        hash_including(
          day_month_year_of_vaccination: "01/01/2024",
          reason_did_not_vaccinate: "the nurse decided John was not well",
          show_additional_instructions: "yes",
          today_or_date_of_vaccination: "1 January 2024",
          outcome_administered: "no",
          outcome_not_administered: "yes"
        )
      )
    end
  end
end
