# frozen_string_literal: true

describe AppVaccinationRecordSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_record) }

  let(:administered_at) { Time.zone.local(2024, 9, 6, 12) }
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programme:, location:) }
  let(:patient_session) { create(:patient_session, session:) }
  let(:vaccine) { programme.vaccines.first }
  let(:batch) do
    create(:batch, name: "ABC", expiry: Date.new(2020, 1, 1), vaccine:)
  end
  let(:other_batch) do
    create(:batch, name: "DEF", expiry: Date.new(2021, 1, 1), vaccine:)
  end
  let(:notes) { "Some notes." }
  let(:location_name) { nil }

  let(:vaccination_record) do
    create(
      :vaccination_record,
      programme:,
      administered_at:,
      batch:,
      vaccine:,
      patient_session:,
      delivery_method: :intramuscular,
      delivery_site: :left_arm_upper_position,
      notes:,
      location_name:,
      pending_changes: {
        batch_id: other_batch&.id,
        delivery_method: :nasal_spray,
        delivery_site: :nose
      }
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
      let(:administered_at) { nil }

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
      let(:other_batch) { nil }

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
      let(:other_batch) { nil }

      it do
        expect(subject).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose volume"
        )
      end
    end
  end

  describe "dose number row" do
    context "for an HPV programme" do
      before { vaccination_record.dose_sequence = 2 }

      it do
        expect(subject).to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose number\nSecond"
        )
      end
    end

    context "for a seasonal programme" do
      let(:programme) { create(:programme, :flu) }

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
      let(:other_batch) { nil }

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
      let(:other_batch) { nil }

      it do
        expect(rendered).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Batch expiry date"
        )
      end
    end
  end

  describe "date row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Vaccination date\n6 September 2024 at 12:00pm"
      )
    end
  end

  describe "nurse row" do
    context "when the user is present" do
      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Nurse\nTest User"
        )
      end
    end

    context "when the user is not present" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          performed_by: nil,
          performed_by_given_name: "Test",
          performed_by_family_name: "User"
        )
      end

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Nurse\nTest User"
        )
      end
    end
  end

  describe "location row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Location\nHogwarts"
      )
    end

    context "when the location is not present" do
      let(:location) { nil }
      let(:location_name) { "Hogwarts" }

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Location\nHogwarts"
        )
      end
    end
  end

  describe "notes row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Notes\nSome notes."
      )
    end

    context "when the notes are not present" do
      let(:notes) { nil }

      it { should_not have_css(".nhsuk-summary-list__row", text: "Notes") }
    end
  end

  describe "with pending changes" do
    let(:component) do
      described_class.new(vaccination_record.with_pending_changes)
    end

    it "highlights changed fields" do
      expect(rendered).to have_css(".app-highlight", text: "Nasal spray")
      expect(rendered).to have_css(".app-highlight", text: "Nose")
      expect(rendered).to have_css(".app-highlight", text: "DEF")
      expect(rendered).to have_css(".app-highlight", text: "1 January 2021")
    end
  end
end
