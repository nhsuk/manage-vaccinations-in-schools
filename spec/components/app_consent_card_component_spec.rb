# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppConsentCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent:, current_user:) }
  let(:current_user) { create(:user, full_name: "Nurse Joy") }

  context "when consent is given" do
    let(:consent) { create(:consent, :given, :from_mum) }

    it { should have_css("h2", text: /Consent given by.*Mum/) }
    it { should have_css("p", text: /Consent updated.*by phone/) }
    it { should have_css("p", text: current_user.full_name) }
  end

  context "when consent is refused" do
    let(:consent) { create(:consent, :refused, :from_dad) }

    it { should have_css("h2", text: /Refusal confirmed by.*Dad/) }
    it { should have_css("p", text: /Refusal.*by phone/) }
    it { should have_css("p", text: current_user.full_name) }
  end

  context "when consent is not provided" do
    let(:consent) { create(:consent, :not_provided, :from_granddad) }

    it { should have_css("h2", text: /Granddad/) }
    it { should have_css("p", text: /No response/) }
    it { should have_css("p", text: current_user.full_name) }
  end
end
