# frozen_string_literal: true

describe SessionsHelper do
  describe "#session_consent_period" do
    subject { travel_to(today) { helper.session_consent_period(session) } }

    let(:today) { Date.new(2024, 10, 1) }

    let(:date) { nil }
    let(:session) { create(:session, academic_year: 2024, date:) }

    it { should eq("Not provided") }

    context "when in the past" do
      let(:date) { Date.new(2024, 9, 1) }

      it { should eq("Closed 31 August") }
    end

    context "when in the near future" do
      let(:date) { Date.new(2024, 10, 14) }

      it { should eq("Open from 23 September until 13 October") }
    end

    context "when in the far future" do
      let(:date) { Date.new(2025, 1, 1) }

      it { should eq("Opens 11 December") }
    end
  end

  describe "#session_dates" do
    subject { helper.session_dates(session) }

    context "without dates" do
      let(:session) { create(:session, dates: []) }

      it { should eq("No dates scheduled") }
    end

    context "with a single date" do
      let(:session) { create(:session, dates: [Date.new(2025, 1, 1)]) }

      it { should eq("1 January 2025") }
    end

    context "with two dates" do
      let(:session) do
        create(:session, dates: [Date.new(2025, 1, 1), Date.new(2025, 1, 2)])
      end

      it { should eq("1 – 2 January 2025") }
    end

    context "with three dates" do
      let(:session) do
        create(
          :session,
          dates: [
            Date.new(2025, 1, 1),
            Date.new(2025, 1, 2),
            Date.new(2025, 1, 3)
          ]
        )
      end

      it { should eq("1 – 3 January 2025 (3 dates)") }
    end

    context "with dates across multiple months" do
      let(:session) do
        create(:session, dates: [Date.new(2025, 1, 31), Date.new(2025, 2, 1)])
      end

      it { should eq("31 January – 1 February 2025") }
    end

    context "with dates across multiple years" do
      let(:session) do
        create(:session, dates: [Date.new(2025, 12, 31), Date.new(2026, 1, 1)])
      end

      it { should eq("31 December 2025 – 1 January 2026") }
    end
  end

  describe "#session_status_tag" do
    subject(:session_status_tag) { helper.session_status_tag(session) }

    context "when unscheduled" do
      let(:session) { create(:session, :unscheduled) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag nhsuk-tag--purple\">No sessions scheduled</strong>"
        )
      end
    end

    context "when scheduled" do
      let(:session) { create(:session, :scheduled) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag nhsuk-tag--blue\">Sessions scheduled</strong>"
        )
      end
    end

    context "when completed" do
      let(:session) { create(:session, :completed) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag nhsuk-tag--green\">All sessions completed</strong>"
        )
      end
    end
  end
end
