require "rails_helper"

RSpec.describe AppConsentDetailsComponent, type: :component do
  let(:consent) { create(:consent, :from_dad, parent_name: "Harry") }
  let(:component) { described_class.new(consent:) }

  subject { page }

  before { render_inline(component) { body } }

  context "when consent is given" do
    describe "summary" do
      subject { component.summary }

      it { should eq("Consent given by Harry (Dad)") }
    end
  end

  context "when consent is given" do
    let(:consent) { create(:consent, :refused, :from_mum, parent_name: "Sue") }

    describe "summary" do
      subject { component.summary }

      it { should eq("Consent refused by Sue (Mum)") }
    end
  end
end
