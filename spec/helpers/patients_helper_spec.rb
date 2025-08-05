# frozen_string_literal: true

describe PatientsHelper do
  describe "#patient_nhs_number" do
    subject(:patient_nhs_number) { helper.patient_nhs_number(patient) }

    context "when the NHS number is present" do
      let(:patient) { build(:patient, nhs_number: "0123456789") }

      it { should be_html_safe }

      it do
        expect(patient_nhs_number).to eq(
          "<span class=\"app-u-monospace nhsuk-u-nowrap\">012 345 6789</span>"
        )
      end

      context "when the patient is invalidated" do
        let(:patient) do
          build(:patient, :invalidated, nhs_number: "0123456789")
        end

        it { should be_html_safe }

        it do
          expect(patient_nhs_number).to eq(
            "<s><span class=\"app-u-monospace nhsuk-u-nowrap\">012 345 6789</span></s>"
          )
        end
      end
    end

    context "when the NHS number is not present" do
      let(:patient) { build(:patient, nhs_number: nil) }

      it { should_not be_html_safe }
      it { should eq("Not provided") }

      context "when the patient is invalidated" do
        let(:patient) { build(:patient, :invalidated, nhs_number: nil) }

        it { should be_html_safe }

        it { expect(patient_nhs_number).to eq("<s>Not provided</s>") }
      end
    end
  end

  describe "#patient_date_of_birth" do
    subject(:patient_date_of_birth) do
      travel_to(today) { helper.patient_date_of_birth(patient) }
    end

    let(:patient) { create(:patient, date_of_birth: Date.new(2000, 1, 1)) }
    let(:today) { Date.new(2024, 1, 1) }

    it { should eq("1 January 2000 (aged 24)") }
  end

  describe "#patient_school" do
    subject(:patient_school) { helper.patient_school(patient) }

    context "without a school" do
      let(:patient) { create(:patient) }

      it { should eq("Unknown school") }
    end

    context "with a school" do
      let(:school) { create(:school, name: "Waterloo Road") }
      let(:patient) { create(:patient, school:) }

      it { should eq("Waterloo Road") }
    end

    context "when home educated" do
      let(:patient) { create(:patient, :home_educated) }

      it { should eq("Home-schooled") }
    end
  end

  describe "#patient_year_group" do
    subject do
      travel_to(today) { helper.patient_year_group(patient, academic_year:) }
    end

    let(:patient) do
      create(:patient, date_of_birth: Date.new(2010, 1, 1), registration: nil)
    end

    let(:today) { Date.new(2024, 1, 1) }

    context "in the current academic year" do
      let(:academic_year) { today.academic_year }

      it { should eq("Year 9") }

      context "with a registration" do
        before do
          patient.registration = "9AB"
          patient.registration_academic_year = today.academic_year
        end

        it { should eq("Year 9 (9AB)") }
      end
    end

    context "in the next academic year" do
      let(:academic_year) { today.academic_year + 1 }

      it { should eq("Year 10 (2024 to 2025 academic year)") }

      context "with a registration" do
        before do
          patient.registration = "9AB"
          patient.registration_academic_year = today.academic_year
        end

        it { should eq("Year 10 (2024 to 2025 academic year)") }
      end
    end
  end
end
