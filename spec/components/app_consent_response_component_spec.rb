require "rails_helper"

RSpec.describe AppConsentResponseComponent, type: :component do
  let(:consents) { [consent] }
  let(:component) { described_class.new(consents:) }
  let(:nurse) do
    create(:user, full_name: "Test User", email: "test@example.com")
  end

  subject { page }

  before { render_inline(component) }

  context "with a single consent" do
    let(:consent) do
      create(
        :consent,
        :given,
        recorded_at: Time.zone.local(2024, 2, 29, 12, 0, 0)
      )
    end
    let(:consents) { [consent] }

    it { should have_text("Consent given (online)") }
    it { should_not have_text(consent.parent_name) }
    it { should have_text("29 Feb 2024 at 12:00pm") }
    it { should_not have_css("ul") }

    context "with consent refused" do
      let(:consent) { create(:consent, :refused) }

      it { should have_text("Consent refused (online)") }
    end

    context "with consent taken over the phone" do
      let(:consent) { create(:consent, :given_verbally, recorded_by: nurse) }

      it { should have_text("Consent given (phone)") }
      it { should have_text("Test User") }
    end

    context "with no response to attempt to get verbal consent" do
      let(:consent) { create(:consent, :not_provided, recorded_by: nurse) }

      it { should have_text("No response when contacted") }
    end
  end

  context "with consent_form" do
    let(:consent_form) do
      create(
        :consent_form,
        :recorded,
        recorded_at: Time.zone.local(2024, 2, 29, 12, 0, 0)
      )
    end
    let(:consents) { [consent_form] }

    it { should have_text("Consent given (online)") }
    it { should have_text("29 Feb 2024 at 12:00pm") }
    it { should_not have_text(consent_form.parent_name) }
  end

  context "with multiple consents" do
    let(:consents) { create_list(:consent, 2, :given) }

    it { should have_css("ul li p", text: "Consent given (online)", count: 2) }
  end
end
