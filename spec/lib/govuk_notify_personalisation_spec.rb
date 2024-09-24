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

  let(:team) do
    create(
      :team,
      name: "Team",
      email: "team@example.com",
      phone: "01234 567890"
    )
  end
  let(:programme) { create(:programme, :flu, team:) }
  let(:patient) { create(:patient, first_name: "John", last_name: "Smith") }
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:session) do
    create(
      :session,
      location:,
      programme:,
      close_consent_at: Date.new(2024, 1, 1),
      date: Date.new(2024, 1, 1)
    )
  end
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:parent) { nil }
  let(:vaccination_record) { nil }

  it do
    expect(personalisation).to eq(
      {
        close_consent_date: "Monday 1 January",
        close_consent_short_date: "1 January",
        consent_link:
          "http://localhost:4000/sessions/#{session.id}/consents/start",
        full_and_preferred_patient_name: "John Smith",
        location_name: "Hogwarts",
        programme_name: "Flu",
        session_date: "Monday 1 January",
        session_short_date: "1 January",
        short_patient_name: "John",
        short_patient_name_apos: "John’s",
        team_email: "team@example.com",
        team_name: "Team",
        team_phone: "01234 567890",
        vaccination: "Flu vaccination"
      }
    )
  end

  context "with a consent" do
    let(:consent) do
      create(:consent, :refused, recorded_at: Date.new(2024, 1, 1))
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
      create(:consent_form, :refused, recorded_at: Date.new(2024, 1, 1))
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
    let(:parent) { create(:parent, name: "John Smith") }

    it { expect(subject).to match(hash_including(parent_name: "John Smith")) }
  end

  context "with a vaccination record" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
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
