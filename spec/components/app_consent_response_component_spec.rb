require "rails_helper"

RSpec.describe AppConsentResponseComponent, type: :component do
  let(:consents) { [consent] }
  let(:component) { described_class.new(consents:) }

  subject { page }

  before { render_inline(component) }

  context "with a single consent" do
    let(:consent) { create(:consent, :given) }
    let(:consents) { [consent] }

    it { should have_text("Consent given (online)") }
    it { should_not have_text(consent.parent_name) }
    it { should have_text(consent.recorded_at.to_fs(:app_date_time)) }
    it { should_not have_css("ul") }

    context "with consent refused" do
      let(:consent) { create(:consent, :refused) }

      it { should have_text("Consent refused (online)") }
    end

    context "with consent taken over the phone, after the record has been confirmed" do
      let(:user) do
        create(:user, full_name: "Test User", email: "test@example.com")
      end
      let(:consent) do
        create(
          :consent,
          :given_verbally,
          recorded_at: Time.zone.local(2024, 2, 27, 14, 0, 0),
          recorded_by: user
        )
      end

      it { should have_text("Consent given (phone)") }
      it { should have_link("Test User", href: "mailto:test@example.com") }
      it { should have_text("27 Feb 2024 at 2:00pm") }
    end

    context "with consent taken over the phone, prior to the record being confirmed" do
      prepend_before(:context) do
        Timecop.freeze(Time.zone.local(2024, 2, 29, 12, 0, 0))
      end
      after { Timecop.return }

      let(:user) do
        create(:user, full_name: "Test User", email: "test@example.com")
      end
      let(:consent) do
        create(:consent, :given_verbally, recorded_at: nil, recorded_by: user)
      end

      it { should have_text("29 Feb 2024 at 12:00pm") }
    end

    context "with no response to attempt to get verbal consent" do
      let(:consent) { create(:consent, :not_provided) }

      it { should have_text("No response when contacted") }
    end
  end

  context "calling the single AppSingleConsentResponseComponent" do
    let(:component) do
      AppConsentResponseComponent::AppSingleConsentResponseComponent.new(
        response: "Consent given",
        route: "online",
        timestamp: Time.zone.local(2024, 2, 29, 12, 0, 0),
        recorded_by:
          create(:user, full_name: "Test User", email: "test@example.com")
      )
    end

    it { should have_text("Consent given (online)") }
    it { should have_text("29 Feb 2024 at 12:00pm") }
    it { should have_link("Test User", href: "mailto:test@example.com") }
  end

  context "with multiple consents" do
    let(:consent1) { create(:consent, :given) }
    let(:consent2) { create(:consent, :given) }
    let(:consents) { [consent1, consent2] }

    it { should have_css("ul li p", text: "Consent given (online)", count: 2) }
  end
end
