# frozen_string_literal: true

describe GovukNotifyPersonalisation do
  subject(:personalisation) do
    described_class.call(
      patient:,
      session:,
      consent:,
      consent_form:,
      parent:,
      programme:,
      vaccination_record:
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:team) do
    create(
      :team,
      name: "Team",
      email: "team@example.com",
      phone: "01234 567890",
      programmes: [programme]
    )
  end

  let(:patient) do
    create(
      :patient,
      given_name: "John",
      family_name: "Smith",
      date_of_birth: Date.current - 13.years
    )
  end
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:session) do
    create(:session, location:, team:, programme:, date: Date.new(2026, 1, 1))
  end
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:parent) { nil }
  let(:vaccination_record) { nil }

  it do
    expect(personalisation).to eq(
      {
        catch_up: "no",
        consent_deadline: "Wednesday 31 December",
        consent_link:
          "http://localhost:4000/consents/#{session.id}/#{programme.id}/start",
        full_and_preferred_patient_name: "John Smith",
        location_name: "Hogwarts",
        next_session_date: "Thursday 1 January",
        next_session_dates: "Thursday 1 January",
        next_session_dates_or: "Thursday 1 January",
        not_catch_up: "yes",
        programme_name: "HPV",
        short_patient_name: "John",
        short_patient_name_apos: "John’s",
        team_email: "team@example.com",
        team_name: "Team",
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
    before { create(:session_date, session:, value: Date.new(2026, 1, 2)) }

    it do
      expect(personalisation).to match(
        hash_including(
          next_session_date: "Thursday 1 January",
          next_session_dates: "Thursday 1 January and Friday 2 January",
          next_session_dates_or: "Thursday 1 January or Friday 2 January",
          subsequent_session_dates_offered_message:
            "If they’re not seen, they’ll be offered the vaccination on Friday 2 January."
        )
      )
    end
  end

  context "with a consent" do
    let(:consent) do
      create(:consent, :refused, programme:, recorded_at: Date.new(2024, 1, 1))
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
        session: create(:session, programme:),
        recorded_at: Date.new(2024, 1, 1)
      )
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

  context "with a parent" do
    let(:parent) { create(:parent, full_name: "John Smith") }

    it do
      expect(subject).to match(hash_including(parent_full_name: "John Smith"))
    end
  end

  context "with a vaccination record" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        recorded_at: Date.new(2024, 1, 1)
      )
    end
    let(:batch) { vaccination_record.batch }

    it do
      expect(personalisation).to match(
        hash_including(
          batch_name: batch.name,
          day_month_year_of_vaccination: "01/01/2024",
          reason_did_not_vaccinate: "the nurse decided John was not well",
          show_additional_instructions: "yes",
          today_or_date_of_vaccination: "1 January 2024"
        )
      )
    end
  end
end
