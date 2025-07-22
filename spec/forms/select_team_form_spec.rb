# frozen_string_literal: true

describe SelectTeamForm do
  subject(:form) { described_class.new(current_user:) }

  let(:team) { create(:team) }
  let(:current_user) { create(:user, teams: [team]) }

  before { create(:team) }

  describe "validations" do
    it { expect(form).to validate_inclusion_of(:team_id).in_array([team.id]) }
  end
end
