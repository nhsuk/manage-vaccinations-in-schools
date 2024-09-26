# frozen_string_literal: true

RSpec.describe SessionsHelper do
  let(:programme) { build(:programme, :flu) }
  let(:location) { build(:location, name: "Waterloo Road") }
  let(:close_consent_at) { nil }
  let(:session) { build(:session, programme:, close_consent_at:, location:) }

  describe "#session_consent_period" do
    subject(:session_consent_period) { helper.session_consent_period(session) }

    it { should eq("Not provided") }

    context "when in the past" do
      let(:close_consent_at) { Date.yesterday }

      it { should start_with("Closed ") }
    end

    context "when in the future" do
      let(:close_consent_at) { Date.tomorrow }

      it { should start_with("Open until ") }
    end
  end

  describe "#session_location" do
    subject(:session_location) { helper.session_location(session) }

    it { should eq("Waterloo Road") }

    context "when location is nil" do
      let(:location) { nil }

      it { should eq("Unknown location") }

      context "when part of a sentence" do
        subject(:session_location) do
          helper.session_location(session, part_of_sentence: true)
        end

        it { should eq("unknown location") }
      end
    end
  end
end
