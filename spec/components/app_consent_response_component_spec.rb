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
    it { should have_text(consent.parent_name) }
    it do
      should have_text(
               "#{consent.created_at.to_fs(:nhsuk_date)} at #{consent.created_at.to_fs(:time)}"
             )
    end
    it do
      should have_link(
               consent.parent_name,
               href: "mailto:#{consent.parent_email}"
             )
    end

    it { should_not have_css("ul") }

    context "with consent refused" do
      let(:consent) { create(:consent, :refused) }

      it { should have_text("Consent refused (online)") }
    end

    context "with consent taken over the phone" do
      let(:consent) { create(:consent, :given_verbally) }

      it { should have_text("Consent given (phone)") }
      it { should have_text("Test User") }
    end
  end

  context "with consent_form" do
    let(:consent_form) { create(:consent_form, :recorded) }
    let(:consents) { [consent_form] }

    it { should have_text("Consent given (online)") }
    it { should have_text(consent_form.parent_name) }
    it do
      should have_text(
               "#{consent_form.created_at.to_fs(:nhsuk_date)} at #{consent_form.created_at.to_fs(:time)}"
             )
    end

    it do
      should have_link(
               consent_form.parent_name,
               href: "mailto:#{consent_form.parent_email}"
             )
    end
  end

  context "with multiple consents" do
    let(:consent1) { create(:consent, :given) }
    let(:consent2) { create(:consent, :given) }
    let(:consents) { [consent1, consent2] }

    it { should have_css("ul li p", text: "Consent given (online)", count: 2) }
  end
end
