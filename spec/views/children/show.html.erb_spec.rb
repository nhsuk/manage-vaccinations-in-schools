require 'rails_helper'

RSpec.describe "children/show", type: :view do
  before(:each) do
    assign(:child, Child.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
