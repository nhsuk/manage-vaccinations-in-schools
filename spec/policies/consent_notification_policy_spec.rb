# frozen_string_literal: true

describe ConsentNotificationPolicy do
  let(:programmes) { [create(:programme, :hpv)] }
  let(:organisation) { create(:organisation, programmes: programmes) }
  let(:user) do
    user = create(:user, organisation: organisation)
    allow(user).to receive(:selected_organisation).and_return(organisation)
    user
  end

  let(:session) { create(:session, organisation:, programmes:) }
  let(:consent_notification) do
    create(:consent_notification, :request, session:)
  end

  let(:other_organisation) { create(:organisation, programmes:) }
  let(:other_session) do
    create(:session, organisation: other_organisation, programmes:)
  end
  let(:another_organisations_consent_notification) do
    create(:consent_notification, :request, session: other_session)
  end

  describe "Scope#resolve" do
    subject do
      ConsentNotificationPolicy::Scope.new(user, ConsentNotification).resolve
    end

    it { should include(consent_notification) }
    it { should_not include(another_organisations_consent_notification) }
  end
end
