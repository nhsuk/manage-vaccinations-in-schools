# frozen_string_literal: true

describe AppVaccinationRecordSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_record, current_user:) }

  let(:current_user) { create(:user) }
  let(:performed_at) { Time.zone.local(2024, 9, 6, 12) }
  let(:outcome) { "administered" }
  let(:location) { create(:school, name: "Hogwarts") }
  let(:programme) { create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:session) { create(:session, programme:, location:, organisation:) }
  let(:patient) { create(:patient) }
  let(:vaccine) { programme.vaccines.first }
  let(:batch) do
    create(:batch, name: "ABC", expiry: Date.new(2026, 1, 1), vaccine:)
  end
  let(:other_batch) do
    create(:batch, name: "DEF", expiry: Date.new(2027, 1, 1), vaccine:)
  end
  let(:notes) { "Some notes." }
  let(:location_name) { nil }

  let(:vaccination_record) do
    create(
      :vaccination_record,
      programme:,
      performed_at:,
      outcome:,
      batch:,
      vaccine:,
      patient:,
      session:,
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
      let(:outcome) { :not_well }

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Outcome\nUnwell"
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
      let(:outcome) { :not_well }
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
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Dose volume\n0.5 ml"
      )
    end

    context "without a vaccine" do
      let(:outcome) { :not_well }
      let(:vaccine) { nil }
      let(:batch) { nil }
      let(:other_batch) { nil }

      it do
        expect(rendered).not_to have_css(
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
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose number\nSecond"
        )
      end
    end

    context "for a seasonal programme" do
      let(:programme) { create(:programme, :flu) }

      it do
        expect(rendered).not_to have_css(
          ".nhsuk-summary-list__row",
          text: "Dose number"
        )
      end
    end
  end

  describe "batch ID row" do
    it { should have_css(".nhsuk-summary-list__row", text: "Batch ID\nABC") }

    context "without a vaccine" do
      let(:outcome) { :not_well }
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
        text: "Batch expiry date\n1 January 2026"
      )
    end

    context "without a vaccine" do
      let(:outcome) { :not_well }
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
        text: "Date\n6 September 2024"
      )
    end
  end

  describe "time row" do
    it do
      expect(rendered).to have_css(
        ".nhsuk-summary-list__row",
        text: "Time\n12:00pm"
      )
    end
  end

  describe "vaccinator row" do
    context "when the user is present" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          performed_by: create(:user, given_name: "Test", family_name: "Nurse")
        )
      end

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Vaccinator\nNURSE, Test"
        )
      end
    end

    context "when the user is not present" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          performed_by: nil,
          performed_by_given_name: "Test",
          performed_by_family_name: "Nurse"
        )
      end

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Vaccinator\nNURSE, Test"
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

    context "when the location is a generic clinic" do
      let(:location) { create(:generic_clinic, organisation:) }
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

      it do
        expect(rendered).to have_css(
          ".nhsuk-summary-list__row",
          text: "Notes\nNot provided"
        )
      end
    end
  end

  describe "with pending changes" do
    let(:component) do
      described_class.new(
        vaccination_record.with_pending_changes,
        current_user:
      )
    end

    it "highlights changed fields" do
      expect(rendered).to have_css(".app-highlight", text: "Nasal spray")
      expect(rendered).to have_css(".app-highlight", text: "Nose")
      expect(rendered).to have_css(".app-highlight", text: "DEF")
      expect(rendered).to have_css(".app-highlight", text: "1 January 2027")
    end
  end
end
