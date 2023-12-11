require "rails_helper"

RSpec.describe AppEmptyListComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new }

  it { should have_css(".app-card--empty-list", text: "No results") }
  it do
    should have_css(
             ".nhsuk-card__content",
             text: "We couldn’t find any children that matched your filters."
           )
  end
end
