require 'rails_helper'

RSpec.describe "students/new", type: :view do
  before(:each) do
    assign(:student, Student.new())
  end

  it "renders new student form" do
    render

    assert_select "form[action=?][method=?]", students_path, "post" do
    end
  end
end
