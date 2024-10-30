# frozen_string_literal: true

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:user) { create(:user, organisations: [organisation]) }

    let(:users_organisations_session) do
      create(:session, organisation:, programme:)
    end
    let(:another_organisations_session) { create(:session, programme:) }

    it { should include(users_organisations_session) }
    it { should_not include(another_organisations_session) }
  end
end
