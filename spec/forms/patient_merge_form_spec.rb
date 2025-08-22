# frozen_string_literal: true

describe PatientMergeForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it { should validate_presence_of(:nhs_number) }
    it { should validate_length_of(:nhs_number).is_equal_to(10) }
  end

  it "normalises NHS numbers" do
    form.nhs_number = "123 456 7890"
    expect(form.nhs_number).to eq("1234567890")
  end
end
