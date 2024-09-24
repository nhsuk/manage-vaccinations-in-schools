# frozen_string_literal: true

RSpec.describe SessionsHelper do
  let(:programme) { build(:programme, :flu) }
  let(:location) { build(:location, name: "Waterloo Road") }
  let(:session) { build(:session, programme:, location:) }

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
