# frozen_string_literal: true

describe PatientArchiveForm do
  subject(:form) { described_class.new }

  let(:patient) { create(:patient) }
  let(:user) { create(:user) }
  let(:other_patient) { create(:patient) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:type).in_array(
        %w[duplicate imported_in_error moved_out_of_area other]
      )
    end

    context "when type is duplicate" do
      before do
        form.type = "duplicate"
        form.patient = patient
        form.current_user = user
      end

      it { should validate_presence_of(:nhs_number) }
      it { should validate_length_of(:nhs_number).is_equal_to(10) }

      context "when NHS number is the patient's own NHS number" do
        before { form.nhs_number = patient.nhs_number }

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:nhs_number]).to include(
            "No other child record has this NHS number. Enter the NHS number of the duplicate record."
          )
        end
      end

      context "when NHS number is different from the patient's own NHS number" do
        before { form.nhs_number = other_patient.nhs_number }

        it "is valid" do
          expect(form).to be_valid
        end
      end
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
