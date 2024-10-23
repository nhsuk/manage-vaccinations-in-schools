# frozen_string_literal: true

describe ClassImportRow do
  subject(:class_import_row) { described_class.new(data:, session:) }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:school) { create(:location, :school, team:) }
  let(:session) { create(:session, team:, programme:, location: school) }

  let(:valid_data) do
    {
      "CHILD_DATE_OF_BIRTH" => "2010-01-01",
      "CHILD_FIRST_NAME" => "Jimmy",
      "CHILD_LAST_NAME" => "Smith",
      "CHILD_POSTCODE" => "SW1A 1AA",
      "CHILD_REGISTRATION" => "8AB",
      "PARENT_1_EMAIL" => "john@example.com",
      "PARENT_1_PHONE" => "07412345678"
    }
  end

  let(:parent_2_data) do
    {
      "PARENT_2_EMAIL" => "jenny@example.com",
      "PARENT_2_PHONE" => "07412345678"
    }
  end

  describe "validations" do
    let(:data) { valid_data }

    it { should be_valid }

    context "when date of birth is outside the programme year group" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "1990-01-01") }

      it "is invalid" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors[:year_group]).to contain_exactly(
          "is not part of this programme"
        )
      end
    end

    context "when date of birth is not a date" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "DDDDDDD") }

      it "is invalid" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors.size).to eq(1)
        expect(class_import_row.errors[:date_of_birth]).to contain_exactly(
          "is required but missing"
        )
      end
    end
  end

  describe "#to_parents" do
    subject(:parents) { class_import_row.to_parents }

    let(:data) { valid_data }

    it "returns a parent" do
      expect(parents.count).to eq(1)
      expect(parents.first).to have_attributes(
        email: "john@example.com",
        phone: "07412345678",
        phone_receive_updates: false
      )
    end

    context "with two parents" do
      let(:data) { valid_data.merge(parent_2_data) }

      it "returns two parents" do
        expect(parents.count).to eq(2)
        expect(parents.first).to have_attributes(
          email: "john@example.com",
          phone: "07412345678"
        )
        expect(parents.second).to have_attributes(
          email: "jenny@example.com",
          phone: "07412345678"
        )
      end
    end

    context "with an existing parent" do
      let!(:existing_parent) do
        create(:parent, full_name: "John Smith", email: "john@example.com")
      end

      it { should contain_exactly(existing_parent) }

      it "doesn't change phone_receive_updates" do
        expect(parents.first.phone_receive_updates).to eq(
          existing_parent.phone_receive_updates
        )
      end

      it "doesn't change full_name" do
        expect(parents.first.full_name).to eq("John Smith")
      end
    end
  end

  describe "#to_patient" do
    subject(:patient) { class_import_row.to_patient }

    let(:data) { valid_data }

    it { should_not be_nil }

    it do
      expect(patient).to have_attributes(
        home_educated: false,
        gender_code: "not_known",
        registration: "8AB"
      )
    end

    context "with an existing patient" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "0123456789"
        )
      end

      it { should eq(existing_patient) }
      it { should be_male }
      it { should have_attributes(nhs_number: "0123456789") }
    end

    describe "#cohort" do
      subject(:cohort) { travel_to(today) { patient.cohort } }

      let(:today) { Date.new(2013, 9, 1) }
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => date_of_birth) }

      context "with a date of birth before September" do
        let(:date_of_birth) { "2000-08-31" }

        it { should have_attributes(team:, birth_academic_year: 1999) }
      end

      context "with a date of birth after September" do
        let(:date_of_birth) { "2000-09-01" }

        it { should have_attributes(team:, birth_academic_year: 2000) }
      end
    end

    describe "#school" do
      subject { patient.school }

      it { should eq(school) }
    end
  end

  describe "#to_parent_relationships" do
    subject(:parent_relationships) do
      class_import_row.to_parent_relationships(
        class_import_row.to_parents,
        class_import_row.to_patient
      )
    end

    let(:data) { valid_data }

    it "returns a parent relationship" do
      expect(parent_relationships.count).to eq(1)
      expect(parent_relationships.first).to be_unknown
    end

    context "with two parents" do
      let(:data) { valid_data.merge(parent_2_data) }

      it "returns two parent relationships" do
        expect(parent_relationships.count).to eq(2)
        expect(parent_relationships.first).to be_unknown
        expect(parent_relationships.second).to be_unknown
      end
    end
  end
end
