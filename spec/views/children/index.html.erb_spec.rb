require "rails_helper"

RSpec.describe "children/index", type: :view do
  let(:dob1) { 6.years.ago }
  let(:dob2) { 8.years.ago }

  before(:each) do
    assign(:children, [Child.create!(dob: dob1), Child.create!(dob: dob2)])
  end

  it "renders a list of children" do
    render
    # cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
  end
end
