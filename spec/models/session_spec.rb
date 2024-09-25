# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  academic_year             :integer          not null
#  active                    :boolean          default(FALSE), not null
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
#  index_sessions_on_team_id  (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Session, type: :model do
  describe "validations" do
    context "when wizard_step is location" do
      subject { build(:session, wizard_step:, programme:) }

      let(:wizard_step) { :location }
      let(:team) { create(:team) }
      let(:programme) { create(:programme, team:) }

      it { should validate_presence_of(:location_id).on(:update) }
    end
  end

  describe "scopes" do
    let!(:active_session) { create(:session) }
    let!(:draft_session) { create(:session, :draft) }
    let!(:today_session) { create(:session, :today) }
    let!(:past_session) { create(:session, :completed) }
    let!(:future_session) { create(:session, :planned) }
    let!(:session_with_dates_encompassing_today) do
      create(
        :session,
        dates: [
          create(:session_date, value: Date.yesterday),
          create(:session_date, value: Date.current + 1.week)
        ]
      )
    end

    describe "#active" do
      subject(:scope) { described_class.active }

      it { should include(active_session) }
      it { should_not include(draft_session) }
    end

    describe "#today" do
      subject(:scope) { described_class.today }

      it do
        expect(subject).to include(
          today_session,
          session_with_dates_encompassing_today
        )
      end

      it { should_not include(past_session, future_session) }
    end

    describe "#completed" do
      subject(:scope) { described_class.completed }

      it { should include(past_session) }
      it { should_not include(active_session, draft_session, future_session) }
    end

    describe "#planned" do
      subject(:scope) { described_class.planned }

      it { should include(future_session) }
      it { should_not include(active_session, draft_session, past_session) }
    end
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
      let(:session) { create(:session, :planned) }

      it { should be_falsey }
    end
  end
end
