require 'rails_helper'

RSpec.describe "children/index", type: :view do
  before(:each) do
    assign(:children, [
      Child.create!,
      Child.create!
    ])
  end

  it "renders a list of children" do
    render
    # cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
  end
end
