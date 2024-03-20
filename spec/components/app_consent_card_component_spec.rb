# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppConsentCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent:) }
  let(:recorded_by) { create(:user, full_name: "Nurse Joy") }

  context "when consent is given" do
    let(:consent) do
      create(:consent, :given, :from_mum, route: :phone, recorded_by:)
    end

    it { should have_css("h2", text: /Consent given by.*Mum/) }
    it { should have_css("p", text: /Consent updated to given \(by phone\)/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end

  context "when consent is refused" do
    let(:consent) do
      create(:consent, :refused, :from_dad, route: :phone, recorded_by:)
    end

    it { should have_css("h2", text: /Refusal confirmed by.*Dad/) }
    it { should have_css("p", text: /Refusal confirmed \(by phone\)/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end

  context "when consent is not provided" do
    let(:consent) do
      create(
        :consent,
        :not_provided,
        :from_granddad,
        route: :phone,
        recorded_by:
      )
    end

    it { should have_css("h2", text: /Granddad/) }
    it { should have_css("p", text: /No response when contacted \(by phone\)/) }
    it { should have_css("p", text: recorded_by.full_name) }
  end
end
