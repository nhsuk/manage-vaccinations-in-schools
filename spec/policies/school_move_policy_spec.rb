# frozen_string_literal: true

describe SchoolMovePolicy do
  subject(:policy) { described_class.new(user, school_move) }

  describe "Scope#resolve" do
    subject(:scope) { SchoolMovePolicy::Scope.new(user, SchoolMove).resolve }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation) }

    let(:team) { create(:team, organisation:, programmes: [programme]) }
    let(:other_team) { create(:team, organisation:, programmes: [programme]) }
    let(:user) { create(:user, team:) }

    let(:session) { create(:session, team:, programmes: [programme]) }
    let(:other_session) { create(:session, team:, programmes: [programme]) }

    context "Patient belonging to two sessions" do
      let(:patient) { create(:patient) }
      let(:patient_session) { create(:patient_session, patient:, session:) }
      let(:other_patient_session) do
        create(:patient_session, patient:, session: other_session)
      end

      let(:school) { create(:school, team:) }
      let(:school_move) { create(:school_move, :to_school, patient:, school:) }

      it { should include(school_move) }

      it "is counted only once" do
        expect(scope.count).to eq(1)
      end
    end
  end
end
