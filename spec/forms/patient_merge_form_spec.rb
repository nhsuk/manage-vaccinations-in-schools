# frozen_string_literal: true

describe PatientMergeForm do
  subject(:form) { described_class.new }

  describe "validations" do
    let(:patient) { create(:patient) }
    let(:team) { create(:team) }
    let(:user) { create(:user, team:) }

    before do
      form.patient = patient
      form.current_user = user
    end

    it { should validate_presence_of(:nhs_number) }
    it { should validate_length_of(:nhs_number).is_equal_to(10) }
  end

  it "normalises NHS numbers" do
    form.nhs_number = "123 456 7890"
    expect(form.nhs_number).to eq("1234567890")
  end

  describe "#existing_patient" do
    let(:team) { create(:team) }
    let(:user) { create(:user, team:) }
    let(:patient) { create(:patient) }
    let(:other_patient) { create(:patient) }

    before do
      form.patient = patient
      form.current_user = user
    end

    context "when searching with the patient's own NHS number" do
      before { form.nhs_number = patient.nhs_number }

      it "does not find itself" do
        expect(form.existing_patient).to be_nil
      end
    end

    context "when searching with another patient's NHS number" do
      before do
        other_patient
        form.nhs_number = other_patient.nhs_number
      end

      it "finds the other patient" do
        expect(form.existing_patient).to eq(other_patient)
      end
    end

    context "when no NHS number is provided" do
      before { form.nhs_number = nil }

      it "returns nil" do
        expect(form.existing_patient).to be_nil
      end
    end
  end
end
