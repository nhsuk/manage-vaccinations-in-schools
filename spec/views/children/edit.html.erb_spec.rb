require "rails_helper"

RSpec.describe "children/edit", type: :view do
  let(:child) { Child.create! }

  before(:each) { assign(:child, child) }

  it "renders the edit child form" do
    render

    assert_select "form[action=?][method=?]", child_path(child), "post" do
    end
  end
end
