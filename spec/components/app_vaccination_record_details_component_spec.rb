# frozen_string_literal: true

require "rails_helper"

describe AppVaccinationRecordDetailsComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_record) }

  let(:administered) { true }
  let(:location) { create(:location, name: "Hogwarts") }
  let(:campaign) { create(:campaign, vaccines: [vaccine].compact) }
  let(:session) { create(:session, campaign:, location:) }
  let(:patient_session) { create(:patient_session, session:) }
  let(:vaccine) { create(:vaccine, :gardasil_9) }
  let(:batch) do
    create(:batch, name: "ABC", expiry: Date.new(2020, 1, 1), vaccine:)
  end

  let(:vaccination_record) do
    create(
      :vaccination_record,
      administered:,
      batch:,
      vaccine:,
      patient_session:
    )
  end

  describe "outcome row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Outcome\nVaccinated"
      )
    end

    context "when not administered" do
      let(:administered) { false }

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Outcome\nNot vaccinated"
        )
      end
    end
  end

  describe "vaccine row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Vaccine\nGardasil 9 (HPV)"
      )
    end

    context "without a vaccine" do
      let(:vaccine) { nil }
      let(:batch) { nil }

      it { should_not have_css(".nhsuk-summary-list__row", text: "Vaccine") }
    end
  end

  describe "method row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Method\nIntramuscular"
      )
    end
  end

  describe "site row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Site\nLeft arm (upper position)"
      )
    end
  end

  describe "dose volume row" do
    it do
      expect(subject).to have_css(
        ".nhsuk-summary-list__row",
        text: "Dose volume\n0.5 ml"
      )
    end

    context "without a vaccine" do
      let(:vaccine) { nil }
      let(:batch) { nil }

      it do
        expect(subject).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose volume"
        )
      end
    end
  end

  describe "dose number row" do
    context "for HPV vaccine" do
      let(:vaccine) { create(:vaccine, :hpv) }

      before { vaccination_record.dose_sequence = 2 }

      it do
        expect(subject).to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose number\nSecond"
        )
      end
    end

    context "for a seasonal vaccine (e.g. flu)" do
      let(:vaccine) { create(:vaccine, :flu) }

      it do
        expect(subject).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose number"
        )
      end
    end
  end

  describe "batch ID row" do
    it { should have_css(".nhsuk-summary-list__row", text: "Batch ID\nABC") }

    context "without a vaccine" do
      let(:vaccine) { nil }
      let(:batch) { nil }

      it { should_not have_css(".nhsuk-summary-list__row", text: "Batch ID") }
    end
  end

  describe "batch expiry date row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Batch expiry date\n1 January 2020"
      )
    end

    context "without a vaccine" do
      let(:vaccine) { nil }
      let(:batch) { nil }

      it do
        expect(rendered).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Batch expiry date"
        )
      end
    end
  end

  describe "date and time row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Date and time\n9 June 2023 at 12:00am"
      )
    end
  end

  describe "nurse row" do
    it { should have_css(".nhsuk-summary-list__row", text: "Nurse\nTest User") }
  end

  describe "location row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Location\nHogwarts"
      )
    end
  end
end
