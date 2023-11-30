require "rails_helper"

RSpec.describe AppConsentResponseComponent, type: :component do
  let(:consents) { [] }
  let(:component) { described_class.new(consents:) }

  subject { page }

  before { render_inline(component) { body } }

  context "with a single consent" do
    let(:consents) { [create(:consent, :given)] }

    it { should have_css("p", text: "Consent given (online)") }

    it "displays the correct date and time" do
      date = consents.first.created_at.to_fs(:nhsuk_date_short_month)
      time = consents.first.created_at.strftime("%-l:%M%P")

      should have_css("p", text: "#{date} at #{time}")
    end

    it { should_not have_css("ul") }
  end

  context "with multiple consents" do
    let(:consent1) { create(:consent, :given) }
    let(:consent2) { create(:consent, :given) }
    let(:consents) { [consent1, consent2] }

    it { should have_css("ul li p", text: "Consent given (online)", count: 2) }
  end

  context "with consent refused" do
    let(:consents) { [create(:consent, :refused)] }

    it { should have_css("p", text: "Consent refused (online)") }

    it "displays the correct date and time" do
      date = consents.first.created_at.to_fs(:nhsuk_date_short_month)
      time = consents.first.created_at.strftime("%-l:%M%P")

      should have_css("p", text: "#{date} at #{time}")
    end

    it { should_not have_css("ul") }
  end
end
