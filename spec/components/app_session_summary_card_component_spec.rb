# frozen_string_literal: true

describe AppSessionSummaryCardComponent do
  subject { page }

  before { render_inline(component) }

  let(:component) { described_class.new(session:) }
  let(:date) { Time.zone.today }
  let(:close_consent_at) { date }
  let(:session) { create(:session, date:, close_consent_at:) }

  it { should have_content(session.location.name) }

  context "when the deadline is the same day as the session" do
    let(:close_consent_at) { date }

    it { should have_content "Allow responses until the day of the session" }
  end

  context "when the deadline is the day before the session" do
    let(:close_consent_at) { date - 1.day }

    it do
      expect(
        subject
      ).to have_content "Allow responses until #{close_consent_at.to_fs(:long_day_of_week)}"
    end
  end

  context "for a session with only 1 patient" do
    before { create(:patient, session:) }

    it "pluralizes 'child' correctly" do
      expect(component.cohort).to eq "1 child"
    end
  end

  context "for a session with more than 1 patient" do
    before { create_list(:patient, 2, session:) }

    it "pluralizes 'child' correctly" do
      expect(component.cohort).to eq "2 children"
    end
  end

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

    it "does not render the deadline for responses" do
      expect(component.deadline_for_responses).to be_nil
    end
  end
end