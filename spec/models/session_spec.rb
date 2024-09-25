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
    describe "#active" do
      subject(:scope) { described_class.active }

      let!(:active_session) { create(:session) }
      let!(:draft_session) { create(:session, :draft) }

      it { should include(active_session) }
      it { should_not include(draft_session) }
    end
  end

  describe "#in_progress?" do
    subject { session.in_progress? }

    context "when the session is scheduled for today" do
      let(:session) { create(:session, :in_progress) }

      it { should be_truthy }
    end

    context "when the session is scheduled in the past" do
      let(:session) { create(:session, :in_past) }

      it { should be_falsey }
    end

    context "when the session is scheduled in the future" do
      let(:session) { create(:session, :in_future) }

      it { should be_falsey }
    end
  end
end
