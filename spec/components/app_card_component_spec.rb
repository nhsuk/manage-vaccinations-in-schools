require "rails_helper"

RSpec.describe AppCardComponent, type: :component do
  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:component) { described_class.new(heading:) }

  subject { page }

  before { render_inline(component) { body } }

  it { should have_css(".nhsuk-card") }
  it { should have_css("h2.nhsuk-card__heading", text: "A Heading") }
  it { should have_css(".nhsuk-card__content", text: "A Body") }

  context "no content is provided" do
    let(:body) { nil }

    it { should_not have_css(".nhsuk-card__content") }
  end
end
