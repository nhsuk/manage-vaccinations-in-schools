require "rails_helper"

RSpec.describe AppFlashSuccessComponent, type: :component do
  subject { described_class.new(flash_success) }

  let(:component) { described_class.new(flash_success) }
  let(:flash_success) { nil }

  context "when flash_success is a hash" do
    let(:flash_success) { { "body" => "Flash body", "title" => "Flash title" } }

    it "assigns body and title correctly" do
      expect(subject.body).to eq(flash_success["body"])
      expect(subject.title).to eq(flash_success["title"])
    end

    describe "rendered page" do
      before { render_inline(component) }

      subject { page }

      it "renders flash_success with title" do
        expect(page).to have_css(
          ".govuk-notification-banner__heading",
          text: flash_success["title"]
        )
        expect(page).to have_css("p", text: flash_success["body"])
      end
    end
  end

  context "when flash_success is a string" do
    let(:flash_success) { "Flash message" }

    it "assigns body correctly" do
      expect(subject.body).to eq(flash_success)
      expect(subject.title).to be_nil
    end

    describe "rendered page" do
      before { render_inline(component) }

      subject { page }

      it "renders flash_success without title" do
        expect(page).to have_css(
          ".govuk-notification-banner__heading",
          text: flash_success
        )
      end
    end
  end
end
