# frozen_string_literal: true

require "rails_helper"

describe AppSessionDetailsComponent, type: :component do
  before { render_inline(component) }

  subject { page }

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
      should have_content "Allow responses until #{close_consent_at.to_fs(:nhsuk_date_day_of_week)}"
    end
  end

  context "for a session with only 1 patient" do
    let(:session) do
      create(:session, date:, close_consent_at:, patients_in_session: 1)
    end

    it "should pluralize 'child' correctly" do
      expect(component.cohort).to eq "1 child"
    end
  end

  context "for a session with more than 1 patient" do
    let(:session) do
      create(:session, date:, close_consent_at:, patients_in_session: 2)
    end

    it "should pluralize 'child' correctly" do
      expect(component.cohort).to eq "2 children"
    end
  end
end
