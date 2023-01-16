require "rails_helper"

RSpec.describe "children/show", type: :view do
  before(:each) { assign(:child, Child.create!) }

  it "renders attributes in <p>" do
    render
  end
end
