require 'rails_helper'

RSpec.describe "children/new", type: :view do
  before(:each) do
    assign(:child, Child.new())
  end

  it "renders new child form" do
    render

    assert_select "form[action=?][method=?]", children_path, "post" do
    end
  end
end
