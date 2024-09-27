# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  academic_year             :integer          not null
#  close_consent_at          :date
#  send_consent_reminders_at :date
#  send_consent_requests_at  :date
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  team_id                   :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id                                    (team_id)
#  index_sessions_on_team_id_and_location_id_and_academic_year  (team_id,location_id,academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Session do
  describe "scopes" do
    let(:programme) { create(:programme) }

    let!(:today_session) { create(:session, :today, programme:) }
    let!(:unscheduled_session) { create(:session, :unscheduled, programme:) }
    let!(:completed_session) { create(:session, :completed, programme:) }
    let!(:scheduled_session) { create(:session, :scheduled, programme:) }

    describe "#today" do
      subject(:scope) { described_class.today }

      it { should contain_exactly(today_session) }
    end

    describe "#unscheduled" do
      subject(:scope) { described_class.unscheduled }

      it { should contain_exactly(unscheduled_session) }
    end

    describe "#scheduled" do
      subject(:scope) { described_class.scheduled }

      it { should contain_exactly(today_session, scheduled_session) }
    end

    describe "#completed" do
      subject(:scope) { described_class.completed }

      it { should contain_exactly(completed_session) }
    end
  end

  it "sets default programmes when creating a new session" do
    hpv_programme = create(:programme, :hpv)
    flu_programme = create(:programme, :flu)

    team = create(:team, programmes: [hpv_programme, flu_programme])
    location = create(:location, :primary)

    session = described_class.new(team:, location:)

    expect(session.programmes).to include(flu_programme)
    expect(session.programmes).not_to include(hpv_programme)
  end

  describe "#today?" do
    subject(:today?) { session.today? }

    context "when the session is scheduled for today" do
      let(:session) { create(:session, :today) }

      it { should be_truthy }
    end

    context "when the session is scheduled in the past" do
      let(:session) { create(:session, :completed) }

      it { should be_falsey }
    end

    context "when the session is scheduled in the future" do
      let(:session) { create(:session, :scheduled) }

      it { should be_falsey }
    end
  end

  describe "#unscheduled?" do
    subject(:unscheduled?) { session.unscheduled? }

    let(:session) { create(:session, date: nil) }

    it { should be(true) }

    context "with a date" do
      before { create(:session_date, session:) }

      it { should be(false) }
    end
  end

  describe "#completed?" do
    subject(:scheduled?) { session.completed? }

    let(:session) { create(:session, date: nil) }

    it { should be(false) }

    context "with a date before today" do
      before { create(:session_date, session:, value: Date.yesterday) }

      it { should be(true) }
    end

    context "with a date after today" do
      before { create(:session_date, session:, value: Date.tomorrow) }

      it { should be(false) }
    end
  end
end
