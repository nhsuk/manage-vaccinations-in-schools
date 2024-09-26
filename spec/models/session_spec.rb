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
    let!(:today_session) { create(:session, :today) }
    let!(:unscheduled_session) { create(:session, :unscheduled) }
    let!(:completed_session) { create(:session, :completed) }
    let!(:scheduled_session) { create(:session, :scheduled) }

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
    team = create(:team)
    location = create(:location, :primary)
    hpv_programme = create(:programme, :hpv, team:)
    flu_programme = create(:programme, :flu, team:)

    session = described_class.new(team:, location:)

    expect(session.programmes).to include(flu_programme)
    expect(session.programmes).not_to include(hpv_programme)
  end

  describe "#today?" do
    subject { session.today? }

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
end
