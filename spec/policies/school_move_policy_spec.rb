# frozen_string_literal: true

describe SchoolMovePolicy do
  describe SchoolMovePolicy::Scope do
    describe "#resolve" do
      subject { described_class.new(user, SchoolMove).resolve }

      let(:programme) { CachedProgramme.sample }
      let(:organisation) { create(:organisation) }

      let(:team) { create(:team, organisation:, programmes: [programme]) }
      let(:other_team) { create(:team, organisation:, programmes: [programme]) }
      let(:user) { create(:user, team:) }

      let(:session) { create(:session, team:, programmes: [programme]) }
      let(:other_session) { create(:session, team:, programmes: [programme]) }

      context "patient belonging to two sessions" do
        let(:patient) { create(:patient) }
        let(:school) { create(:school, team:) }
        let(:school_move) do
          create(:school_move, :to_school, patient:, school:)
        end

        before do
          create(:patient_location, patient:, session:)
          create(:patient_location, patient:, session: other_session)
        end

        it { should contain_exactly(school_move) }
      end
    end
  end
end
