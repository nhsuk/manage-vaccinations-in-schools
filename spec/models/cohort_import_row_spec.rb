# frozen_string_literal: true

describe CohortImportRow do
  subject(:cohort_import_row) do
    described_class.new(data: data_as_csv_row, team:, academic_year:)
  end

  # FIXME: Don't re-implement behaviour of `CSVParser`.
  let(:data_as_csv_row) do
    data.each_with_object({}) do |(key, value), hash|
      hash[
        key.strip.downcase.tr("-", "_").tr(" ", "_").to_sym
      ] = CSVParser::Field.new(value, nil, nil, key)
    end
  end

  let(:today) { Date.new(2024, 12, 1) }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:academic_year) { AcademicYear.pending }

  let(:school_urn) { "123456" }

  let(:valid_data) do
    {
      "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
      "CHILD_ADDRESS_LINE_2" => "",
      "CHILD_TOWN" => "London",
      "CHILD_POSTCODE" => "SW1A 1AA",
      "CHILD_FIRST_NAME" => "Jimmy",
      "CHILD_LAST_NAME" => "Smith",
      "CHILD_PREFERRED_FIRST_NAME" => "Jim",
      "CHILD_PREFERRED_LAST_NAME" => "Smithy",
      "CHILD_DATE_OF_BIRTH" => "2010-01-01",
      "CHILD_GENDER" => "Male",
      "CHILD_NHS_NUMBER" => "9990000018",
      "CHILD_REGISTRATION" => "8AB",
      "CHILD_SCHOOL_URN" => school_urn
    }
  end

  let(:parent_1_data) do
    {
      "PARENT_1_EMAIL" => "john@example.com",
      "PARENT_1_NAME" => "John Smith",
      "PARENT_1_PHONE" => "07412345678",
      "PARENT_1_RELATIONSHIP" => "Father"
    }
  end

  let(:parent_2_data) do
    {
      "PARENT_2_EMAIL" => "jenny@example.com",
      "PARENT_2_NAME" => "Jenny Smith",
      "PARENT_2_PHONE" => "07412345678",
      "PARENT_2_RELATIONSHIP" => "Mother"
    }
  end

  let!(:school) { create(:school, urn: "123456", team:) }

  describe "validations" do
    let(:data) { valid_data }

    it { should be_valid }

    context "when date of birth is outside the programme year group" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "2000-01-01") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(
          cohort_import_row.errors["CHILD_DATE_OF_BIRTH"]
        ).to contain_exactly("is not part of this programme")
      end
    end

    context "when date of birth is not a date" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "DDDDDDD") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(
          cohort_import_row.errors["CHILD_DATE_OF_BIRTH"]
        ).to contain_exactly("should be formatted as YYYY-MM-DD")
      end
    end

    context "when date of birth is in the previous century" do
      let(:data) do
        valid_data.merge(
          { "CHILD_DATE_OF_BIRTH" => "1911-01-01", "CHILD_YEAR_GROUP" => "9" }
        )
      end

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(
          cohort_import_row.errors["CHILD_DATE_OF_BIRTH"]
        ).to contain_exactly("is too old to still be in school")
      end
    end

    context "with an invalid NHS number" do
      let(:data) { { "CHILD_NHS_NUMBER" => "TP01234567" } }

      it "has errors" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors["CHILD_NHS_NUMBER"]).to eq(
          ["should be a valid NHS number with 10 characters"]
        )
      end
    end

    context "with an invalid school URN" do
      let(:data) { valid_data.merge("CHILD_SCHOOL_URN" => "123456789") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["CHILD_SCHOOL_URN"]).to contain_exactly(
          "The school URN is not recognised. If you’ve checked the URN, " \
            "and you believe it’s valid, contact our support team."
        )
      end
    end

    context "with a school for a different team" do
      let(:data) { valid_data }

      before { school.update!(subteam: nil) }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors["CHILD_SCHOOL_URN"].first).to include(
          "The school URN is not recognised."
        )
      end
    end

    context "with an invalid year group" do
      let(:data) { valid_data.merge("CHILD_YEAR_GROUP" => "abc") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["CHILD_YEAR_GROUP"]).to contain_exactly(
          "is not a valid year group"
        )
      end
    end

    context "when the given name has invalid characters" do
      let(:data) { valid_data.merge("CHILD_FIRST_NAME" => "J£mmy") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["CHILD_FIRST_NAME"]).to contain_exactly(
          "includes invalid character(s)"
        )
      end
    end

    context "when the family name has invalid characters" do
      let(:data) { valid_data.merge("CHILD_LAST_NAME" => "ᶚmith") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["CHILD_LAST_NAME"]).to contain_exactly(
          "includes invalid character(s)"
        )
      end
    end

    context "when the preferred given name has invalid characters" do
      let(:data) { valid_data.merge("CHILD_PREFERRED_FIRST_NAME" => "J£m") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(
          cohort_import_row.errors["CHILD_PREFERRED_FIRST_NAME"]
        ).to contain_exactly("includes invalid character(s)")
      end
    end

    context "when the preferred family name has invalid characters" do
      let(:data) { valid_data.merge("CHILD_PREFERRED_LAST_NAME" => "ᶚmithy") }

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(
          cohort_import_row.errors["CHILD_PREFERRED_LAST_NAME"]
        ).to contain_exactly("includes invalid character(s)")
      end
    end

    context "when the first parent's full name has invalid characters" do
      let(:data) do
        valid_data.merge(parent_1_data).merge("PARENT_1_NAME" => "John© Smith")
      end

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["PARENT_1_NAME"]).to contain_exactly(
          "includes invalid character(s)"
        )
      end
    end

    context "when the second parent's full name has invalid characters" do
      let(:data) do
        valid_data.merge(parent_2_data).merge("PARENT_2_NAME" => "John© Smith")
      end

      it "is invalid" do
        expect(cohort_import_row).to be_invalid
        expect(cohort_import_row.errors.size).to eq(1)
        expect(cohort_import_row.errors["PARENT_2_NAME"]).to contain_exactly(
          "includes invalid character(s)"
        )
      end
    end
  end

  describe "#to_parents" do
    subject(:parents) { cohort_import_row.to_parents }

    let(:data) { valid_data }

    it { should be_empty }

    context "with one parent" do
      let(:data) { valid_data.merge(parent_1_data) }

      it "returns a parent" do
        expect(parents.count).to eq(1)
        expect(parents.first).to have_attributes(
          full_name: "John Smith",
          email: "john@example.com",
          phone: "07412 345678",
          phone_receive_updates: false
        )
      end
    end

    context "with two parents" do
      let(:data) { valid_data.merge(parent_1_data).merge(parent_2_data) }

      it "returns two parents" do
        expect(parents.count).to eq(2)
        expect(parents.first).to have_attributes(
          full_name: "John Smith",
          email: "john@example.com",
          phone: "07412 345678"
        )
        expect(parents.second).to have_attributes(
          full_name: "Jenny Smith",
          email: "jenny@example.com",
          phone: "07412 345678"
        )
      end
    end

    context "with an existing parent" do
      let(:data) { valid_data.merge(parent_2_data) }

      let!(:existing_parent) do
        create(:parent, full_name: "Jenny Smith", email: "jenny@example.com")
      end

      it { should eq([existing_parent]) }

      it "doesn't change phone_receive_updates" do
        expect(parents.first.phone_receive_updates).to eq(
          existing_parent.phone_receive_updates
        )
      end
    end

    context "when uploading different caps name" do
      let(:capitalised_parent_2_data) do
        {
          "PARENT_2_EMAIL" => "jenny@example.com",
          "PARENT_2_NAME" => "Jenny Smith"
        }
      end
      let(:data) { valid_data.merge(capitalised_parent_2_data) }

      let!(:existing_parent) do
        create(:parent, full_name: "JENNY SMITH", email: "jenny@example.com")
      end

      it { should eq([existing_parent]) }
    end

    context "with fancy apostrophes" do
      let(:data) do
        valid_data
          .merge(parent_1_data)
          .merge(parent_2_data)
          .merge(
            "PARENT_1_NAME" => "Jane OʼReilly",
            "PARENT_2_NAME" => "Jacob O`Reilly"
          )
      end

      it "converts fancy apostrophes to plain apostrophes" do
        expect(parents.first.full_name).to eq("Jane O'Reilly")
        expect(parents.second.full_name).to eq("Jacob O'Reilly")
      end
    end
  end

  describe "#to_patient" do
    subject(:patient) { cohort_import_row.to_patient }

    around { |example| travel_to(today) { example.run } }

    let(:data) { valid_data }

    it { should_not be_nil }

    it do
      expect(patient).to have_attributes(
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: "male",
        home_educated: false,
        registration: "8AB",
        registration_academic_year: AcademicYear.pending,
        school: nil,
        birth_academic_year: 2009
      )
    end

    context "with a specific year group provided" do
      let(:data) { valid_data.merge("CHILD_YEAR_GROUP" => "11") }

      it { should have_attributes(birth_academic_year: 2008) }
    end

    context "when gender is not provided" do
      let(:data) { valid_data.except("CHILD_GENDER") }

      it { should_not be_nil }

      it { should have_attributes(gender_code: "not_known") }
    end

    context "with an existing patient" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          registration_academic_year: 2023
        )
      end

      it { should eq(existing_patient) }
      it { should be_male }
      it { should have_attributes(nhs_number: "9990000018") }

      it "stages the registration" do
        expect(patient.registration).not_to eq("8AB")
        expect(patient.registration_academic_year).not_to eq(
          AcademicYear.pending
        )
        expect(patient.pending_changes).to include(
          "registration" => "8AB",
          "registration_academic_year" => AcademicYear.pending
        )
      end
    end

    context "with an existing patient without gender" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "not_known",
          given_name: "Jimmy",
          preferred_given_name: "Jim",
          nhs_number: "9990000018",
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "saves the incoming gender" do
        expect(patient).to have_attributes(gender_code: "male")
      end

      it "doesn't stage the gender differences" do
        expect(patient.pending_changes).to be_empty
      end
    end

    context "with an existing patient already with gender" do
      let!(:existing_patient) do
        create(
          :patient,
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          address_postcode: "SW1A 1AA",
          given_name: "Jimmy",
          family_name: "Smith",
          preferred_given_name: "Jim",
          gender_code: "female",
          nhs_number: "9990000018",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "does not save the incoming gender" do
        expect(patient).to have_attributes(gender_code: "female")
      end

      it "does stage the gender differences" do
        expect(patient.pending_changes).to include("gender_code" => "male")
      end
    end

    context "with an existing patient without preferred names" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "saves the incoming preferred names" do
        expect(patient).to have_attributes(
          preferred_given_name: "Jim",
          preferred_family_name: "Smithy"
        )
      end

      it "doesn't stage the preferred names differences" do
        expect(patient.pending_changes).to be_empty
      end
    end

    context "with an existing patient already with preferred names" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          given_name: "Jimmy",
          family_name: "Smith",
          preferred_given_name: "Jimothy",
          preferred_family_name: "Smithers",
          nhs_number: "9990000018",
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "does not save the incoming gender" do
        expect(patient).to have_attributes(
          preferred_given_name: "Jimothy",
          preferred_family_name: "Smithers"
        )
      end

      it "does stage the gender differences" do
        expect(patient.pending_changes).to include(
          "preferred_given_name" => "Jim",
          "preferred_family_name" => "Smithy"
        )
      end
    end

    context "with an existing patient without address (ex. postcode)" do
      let!(:existing_patient) do
        create(
          :patient,
          family_name: "Smith",
          given_name: "Jimmy",
          preferred_given_name: "Jim",
          gender_code: "male",
          nhs_number: "9990000018",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB",
          address_line_1: nil,
          address_line_2: nil,
          address_town: nil,
          address_postcode: "SW1A 1AA"
        )
      end

      it { should eq(existing_patient) }

      it "saves the incoming address" do
        expect(patient).to have_attributes(
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          address_postcode: "SW1A 1AA"
        )
      end

      it "doesn't stage the incoming address" do
        expect(patient.pending_changes).to be_empty
      end
    end

    context "with an existing patient with a different address (but matching postcode)" do
      let!(:existing_patient) do
        create(
          :patient,
          family_name: "Smith",
          given_name: "Jimmy",
          preferred_given_name: "Jim",
          gender_code: "male",
          nhs_number: "9990000018",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB",
          address_line_1: "15 Woodstock Road",
          address_line_2: "Jericho",
          address_town: "Oxford",
          address_postcode: "SW1A 1AA"
        )
      end

      it { should eq(existing_patient) }

      it "saves the incoming address" do
        expect(patient).to have_attributes(
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          address_postcode: "SW1A 1AA"
        )
      end

      it "doesn't stage the incoming address" do
        expect(patient.pending_changes).to be_empty
      end
    end

    context "with an existing patient already with an address" do
      let!(:existing_patient) do
        create(
          :patient,
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          address_line_1: "20 Woodstock Road",
          address_line_2: "",
          address_town: "Oxford",
          address_postcode: "OX2 6HD",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "does not save the incoming address" do
        expect(patient).to have_attributes(
          address_line_1: "20 Woodstock Road",
          address_line_2: "",
          address_town: "Oxford",
          address_postcode: "OX2 6HD"
        )
      end

      it "does stage the address differences" do
        expect(patient.pending_changes).to include(
          "address_line_1" => "10 Downing Street",
          "address_postcode" => "SW1A 1AA",
          "address_town" => "London"
        )
      end
    end

    context "with an existing patient with different capitalisation" do
      let(:data) do
        {
          "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
          "CHILD_PREFERRED_FIRST_NAME" => "Jim",
          "CHILD_DATE_OF_BIRTH" => "2010-01-01",
          "CHILD_FIRST_NAME" => "Jimmy",
          "CHILD_GENDER" => "Male",
          "CHILD_LAST_NAME" => "Smith",
          "CHILD_PREFERRED_LAST_NAME" => "Smithy",
          "CHILD_NHS_NUMBER" => "9990000018",
          "CHILD_POSTCODE" => "sw1a 1aa",
          "CHILD_SCHOOL_URN" => school_urn,
          "CHILD_TOWN" => "London"
        }
      end

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "SMITH",
          gender_code: "male",
          given_name: "JIMMY",
          nhs_number: "9990000018",
          address_line_1: "10 DOWNING STREET",
          preferred_given_name: "JIM",
          preferred_family_name: "SMITHY",
          date_of_birth: Date.new(2010, 1, 1),
          address_town: "LONDON"
        )
      end

      it { should eq(existing_patient) }

      it "saves the incoming values" do
        expect(patient).to have_attributes(
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          address_line_1: "10 Downing Street",
          preferred_given_name: "Jim",
          preferred_family_name: "Smithy",
          address_town: "London"
        )
      end

      it "doesn't stage the capitalisation differences" do
        expect(patient.pending_changes).to be_empty
      end
    end
  end

  describe "#to_school_move" do
    subject(:school_move) { cohort_import_row.to_school_move(patient) }

    let(:data) { valid_data }

    let(:patient) { create(:patient, school: create(:school)) }

    it { should_not be_nil }

    context "with a date of death" do
      before { patient.update!(date_of_death: today) }

      it { should be_nil }
    end

    describe "#school" do
      subject { school_move.school }

      context "with a school location" do
        let(:school_urn) { "123456" }

        it { should eq(school) }
      end

      context "with an unknown school" do
        let(:school_urn) { "888888" }

        it { should be_nil }
      end

      context "when home educated" do
        let(:school_urn) { "999999" }

        it { should be_nil }
      end
    end

    describe "#home_educated" do
      subject { school_move.home_educated }

      context "with a school location" do
        let(:school_urn) { "123456" }

        it { should be_nil }
      end

      context "with an unknown school" do
        let(:school_urn) { "888888" }

        it { should be(false) }
      end

      context "when home educated" do
        let(:school_urn) { "999999" }

        it { should be(true) }
      end
    end

    context "with an existing patient that was previously removed from cohort" do
      subject(:school_move) do
        cohort_import_row.to_school_move(existing_patient)
      end

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          team: nil,
          school: Location.first
        )
      end

      let(:data) { valid_data }

      it { should_not be_nil }
    end

    context "with an existing patient that was previously archived" do
      subject(:school_move) do
        cohort_import_row.to_school_move(existing_patient)
      end

      let(:data) { valid_data }

      let(:location) { Location.school.find_by_urn_and_site!("123456") }
      let(:session) do
        create(:session, location:, team:, programmes: [programme])
      end

      let(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018",
          session:
        )
      end

      before do
        create(
          :archive_reason,
          :moved_out_of_area,
          team:,
          patient: existing_patient
        )
      end

      it { should_not be_nil }
    end
  end

  describe "#to_parent_relationships" do
    subject(:parent_relationships) do
      cohort_import_row.to_parent_relationships(
        cohort_import_row.to_parents,
        cohort_import_row.to_patient
      )
    end

    let(:data) { valid_data }

    it { should be_empty }

    context "with one parent" do
      let(:data) { valid_data.merge(parent_1_data) }

      it "returns a parent relationship" do
        expect(parent_relationships.count).to eq(1)
        expect(parent_relationships.first).to be_father
      end
    end

    context "with two parents" do
      let(:data) { valid_data.merge(parent_1_data).merge(parent_2_data) }

      it "returns two parent relationships" do
        expect(parent_relationships.count).to eq(2)
        expect(parent_relationships.first).to be_father
        expect(parent_relationships.second).to be_mother
      end
    end

    context "with a guardian" do
      let(:data) do
        valid_data.merge(parent_1_data).merge(
          "PARENT_1_RELATIONSHIP" => "Guardian"
        )
      end

      it "returns a guardian" do
        expect(parent_relationships.count).to eq(1)
        expect(parent_relationships.first).to be_guardian
      end
    end

    context "with an other relationship" do
      let(:data) do
        valid_data.merge(parent_1_data).merge(
          "PARENT_1_RELATIONSHIP" => "Stepdad"
        )
      end

      it "returns an other relationship" do
        expect(parent_relationships.count).to eq(1)
        expect(parent_relationships.first).to be_other
        expect(parent_relationships.first.other_name).to eq("Stepdad")
      end
    end

    context "when using shorted versions" do
      let(:data) do
        valid_data
          .merge(parent_1_data)
          .merge(parent_2_data)
          .merge(
            "PARENT_1_RELATIONSHIP" => "Dad",
            "PARENT_2_RELATIONSHIP" => "Mum"
          )
      end

      it "returns two parent relationships" do
        expect(parent_relationships.count).to eq(2)
        expect(parent_relationships.first).to be_father
        expect(parent_relationships.second).to be_mother
      end
    end
  end

  describe "#import_attributes" do
    context "with fancy apostrophes" do
      let(:data) do
        valid_data.merge(
          {
            "CHILD_FIRST_NAME" => "Mickʼee",
            "CHILD_LAST_NAME" => "OʼReilly",
            "CHILD_PREFERRED_FIRST_NAME" => "Mickʼee",
            "CHILD_PREFERRED_LAST_NAME" => "OʼReilly"
          }
        )
      end

      it "converts fancy apostrophes to plain apostrophes" do
        expect(cohort_import_row.import_attributes).to include(
          given_name: "Mick'ee",
          family_name: "O'Reilly",
          preferred_given_name: "Mick'ee",
          preferred_family_name: "O'Reilly"
        )
      end
    end
  end
end
