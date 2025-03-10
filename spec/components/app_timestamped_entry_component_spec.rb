# frozen_string_literal: true

describe AppTimestampedEntryComponent do
  subject(:rendered) { render_inline(component) }

  context "with text and a timestamp" do
    let(:component) do
      described_class.new(
        text: "Summary of a thing",
        timestamp: Time.zone.local(2024, 2, 17, 12, 23, 0)
      )
    end

    let(:consent) { create(:consent, :given) }
    let(:consents) { [consent] }

    it { should have_text("Summary of a thing") }
    it { should have_text("17 February 2024 at 12:23pm") }
  end

  context "with a user who recorded the entry" do
    let(:component) do
      described_class.new(
        text: "Summary of a thing",
        timestamp: Time.zone.local(2024, 2, 17, 12, 23, 0),
        recorded_by:
          create(
            :user,
            family_name: "User",
            given_name: "Test",
            email: "test@example.com"
          )
      )
    end

    it { should have_link("USER, Test", href: "mailto:test@example.com") }
  end
end
