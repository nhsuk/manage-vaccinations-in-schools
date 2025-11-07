# frozen_string_literal: true

describe ConsentNotificationPolicy do
  let(:programmes) { [CachedProgramme.hpv] }
  let(:team) { create(:team, programmes: programmes) }
  let(:user) do
    user = create(:user, team:)
    allow(user).to receive(:selected_team).and_return(team)
    user
  end

  let(:session) { create(:session, team:, programmes:) }
  let(:consent_notification) do
    create(:consent_notification, :request, session:)
  end

  let(:other_team) { create(:team, programmes:) }
  let(:other_session) { create(:session, team: other_team, programmes:) }
  let(:another_teams_consent_notification) do
    create(:consent_notification, :request, session: other_session)
  end

  describe "Scope#resolve" do
    subject do
      ConsentNotificationPolicy::Scope.new(user, ConsentNotification).resolve
    end

    it { should include(consent_notification) }
    it { should_not include(another_teams_consent_notification) }
  end
end
