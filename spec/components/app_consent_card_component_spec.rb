# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppConsentCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent:) }
  let(:recorded_by) { create(:user, full_name: "Nurse Joy") }

  context "when consent is given" do
    let(:consent) { create(:consent, :given, :from_mum, recorded_by:) }

    it { should have_css("h2", text: /Consent given by.*Mum/) }
    it { should have_css("p", text: /Consent updated.*by phone/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end

  context "when consent is refused" do
    let(:consent) { create(:consent, :refused, :from_dad, recorded_by:) }

    it { should have_css("h2", text: /Refusal confirmed by.*Dad/) }
    it { should have_css("p", text: /Refusal.*by phone/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end

  context "when consent is not provided" do
    let(:consent) do
      create(:consent, :not_provided, :from_granddad, recorded_by:)
    end

    it { should have_css("h2", text: /Granddad/) }
    it { should have_css("p", text: /No response/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end
end
