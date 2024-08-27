# frozen_string_literal: true

RSpec.describe SessionsHelper, type: :helper do
  let(:campaign) { build(:campaign, name: "Flu") }
  let(:location) { build(:location, name: "Waterloo Road") }
  let(:session) { build(:session, campaign:, location:) }

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

  describe "#session_name" do
    subject(:session_name) { helper.session_name(session) }

    it { should eq("Flu session at Waterloo Road") }

    context "when location is nil" do
      let(:location) { nil }

      it { should eq("Flu session at unknown location") }
    end
  end
end
