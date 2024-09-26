# frozen_string_literal: true

describe AppSessionSummaryCardComponent do
  subject { page }

  before { render_inline(component) }

  let(:component) { described_class.new(session:) }
  let(:date) { Date.new(2024, 1, 1) }
  let(:close_consent_at) { date }
  let(:session) { create(:session, date:, close_consent_at:) }

  it { should have_content("1 January 2024") }

  context "for a session with the minimum amount of information" do
    let(:session) do
      Session.new(
        location: create(:location, :school),
        programmes: [create(:programme, :hpv)],
        date:
      )
    end

    it "does not render the consent requests" do
      expect(component.consent_requests).to be_nil
    end

    it "does not render the consent reminders" do
      expect(component.consent_reminders).to be_nil
    end
  end
end
