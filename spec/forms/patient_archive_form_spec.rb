# frozen_string_literal: true

describe PatientArchiveForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:type).in_array(
        %w[duplicate imported_in_error moved_out_of_area other]
      )
    end

    context "when type is duplicate" do
      before { form.type = "duplicate" }

      it { should validate_presence_of(:nhs_number) }
      it { should validate_length_of(:nhs_number).is_equal_to(10) }
    end

    context "when type is other" do
      before { form.type = "other" }

      it { should validate_presence_of(:other_details) }
      it { should validate_length_of(:other_details).is_at_most(300) }
    end
  end

  it "normalises NHS numbers" do
    form.nhs_number = "123 456 7890"
    expect(form.nhs_number).to eq("1234567890")
  end
end
