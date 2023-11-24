require "rails_helper"

RSpec.describe AppEmptyListComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:message) { "No items found." }
  let(:component) { described_class.new(message:) }

  it { should have_css(".app-empty-list", text: "No results") }
  it { should have_css(".nhsuk-card__content", text: message) }
end
