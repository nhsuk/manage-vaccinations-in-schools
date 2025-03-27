# frozen_string_literal: true

describe SessionsHelper do
  let(:location) { create(:school, name: "Waterloo Road") }
  let(:date) { nil }
  let(:session) { create(:session, academic_year: 2024, date:, location:) }

  describe "#session_consent_period" do
    subject(:session_consent_period) do
      helper.session_consent_period(session, in_sentence:)
    end

    context "when in a sentence" do
      let(:in_sentence) { true }

      it { should eq("not provided") }

      context "when in the past" do
        let(:date) { Date.yesterday }

        it { should start_with("closed ") }
      end

      context "when in the future" do
        let(:date) { Date.tomorrow }

        it { should start_with("open until ") }
      end
    end

    context "when not in a sentence" do
      let(:in_sentence) { false }

      it { should eq("Not provided") }

      context "when in the past" do
        let(:date) { Date.yesterday }

        it { should start_with("Closed ") }
      end

      context "when in the future" do
        let(:date) { Date.tomorrow }

        it { should start_with("Open until ") }
      end
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
