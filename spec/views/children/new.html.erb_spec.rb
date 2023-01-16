require "rails_helper"

RSpec.describe "children/new", type: :view do
  before(:each) { assign(:child, Child.new) }

  it "renders new child form" do
    render

    assert_select "form[action=?][method=?]", children_path, "post" do
    end
  end
end
