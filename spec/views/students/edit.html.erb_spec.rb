require 'rails_helper'

RSpec.describe "students/edit", type: :view do
  let(:student) {
    Student.create!()
  }

  before(:each) do
    assign(:student, student)
  end

  it "renders the edit student form" do
    render

    assert_select "form[action=?][method=?]", student_path(student), "post" do
    end
  end
end
