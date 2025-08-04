# frozen_string_literal: true

describe ClassImportRow do
  subject(:class_import_row) do
    described_class.new(
      data: data_as_csv_row,
      team: session.team,
      location: session.location,
      year_groups: session.year_groups
    )
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

  let(:programmes) { [create(:programme)] }
  let(:team) { create(:team, programmes:) }
  let(:school) { create(:school, team:) }
  let(:session) { create(:session, team:, programmes:, location: school) }

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
        expect(
          class_import_row.errors["CHILD_DATE_OF_BIRTH"]
        ).to contain_exactly("is not part of this programme")
      end
    end

    context "when date of birth is not a date" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "DDDDDDD") }

      it "is invalid" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors.size).to eq(1)
        expect(
          class_import_row.errors["CHILD_DATE_OF_BIRTH"]
        ).to contain_exactly("should be formatted as YYYY-MM-DD")
      end
    end

    context "with an invalid NHS number" do
      let(:data) { { "CHILD_NHS_NUMBER" => "TP01234567" } }

      it "has errors" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors["CHILD_NHS_NUMBER"]).to eq(
          ["should be a valid NHS number with 10 characters"]
        )
      end
    end

    context "with an invalid postcode" do
      let(:data) { valid_data.merge("CHILD_POSTCODE" => "not a postcode") }

      it "is invalid" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors.size).to eq(1)
        expect(class_import_row.errors["CHILD_POSTCODE"]).to contain_exactly(
          "should be a postcode, like SW1A 1AA"
        )
      end
    end

    context "with an invalid year group" do
      let(:data) { valid_data.merge("CHILD_YEAR_GROUP" => "abc") }

      it "is invalid" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors.size).to eq(1)
        expect(class_import_row.errors["CHILD_YEAR_GROUP"]).to contain_exactly(
          "is not a valid year group"
        )
      end
    end

    context "vaccination in a session where name-like fields have length greater than 300" do
      let(:invalid_name_length) { "a" * 301 }
      let(:data) do
        {
          "CHILD_FIRST_NAME" => invalid_name_length,
          "CHILD_LAST_NAME" => invalid_name_length
        }
      end

      it "has errors" do
        expect(class_import_row).to be_invalid
        expect(class_import_row.errors["CHILD_FIRST_NAME"]).to include(
          "is greater than 300 characters long"
        )
        expect(class_import_row.errors["CHILD_LAST_NAME"]).to include(
          "is greater than 300 characters long"
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
        phone: "07412 345678",
        phone_receive_updates: false
      )
    end

    context "with two parents" do
      let(:data) { valid_data.merge(parent_2_data) }

      it "returns two parents" do
        expect(parents.count).to eq(2)
        expect(parents.first).to have_attributes(
          email: "john@example.com",
          phone: "07412 345678"
        )
        expect(parents.second).to have_attributes(
          email: "jenny@example.com",
          phone: "07412 345678"
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

    context "when uploading different caps name" do
      let!(:existing_parent) do
        create(:parent, full_name: "JENNY SMITH", email: "jenny@example.com")
      end

      let(:capitalised_parent_2_data) do
        {
          "PARENT_2_EMAIL" => "jenny@example.com",
          "PARENT_2_NAME" => "Jenny Smith"
        }
      end
      let(:data) { valid_data.merge(capitalised_parent_2_data) }

      it { should include(existing_parent) }
    end
  end

  describe "#to_patient" do
    subject(:patient) { class_import_row.to_patient }

    around { |example| travel_to(today) { example.run } }

    let(:data) { valid_data }

    it { should_not be_nil }

    it do
      expect(patient).to have_attributes(
        date_of_birth: Date.new(2010, 1, 1),
        gender_code: "not_known",
        home_educated: false,
        registration: "8AB",
        registration_academic_year: AcademicYear.pending,
        school: nil,
        year_group: 10
      )
    end

    context "with a specific year group provided" do
      let(:data) { valid_data.merge("CHILD_YEAR_GROUP" => "11") }

      it { should have_attributes(year_group: 11) }
    end

    context "with an existing patient" do
      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          date_of_birth: Date.new(2010, 1, 1),
          family_name: "Smith",
          gender_code: "male",
          given_name: "Jimmy",
          nhs_number: "9990000018"
        )
      end

      it { should eq(existing_patient) }
      it { should be_male }
      it { should have_attributes(nhs_number: "9990000018") }

      it "overwrites registration" do
        expect(patient.registration).to eq("8AB")
        expect(patient.registration_academic_year).to eq(AcademicYear.pending)
        expect(patient.pending_changes).not_to have_key("registration")
      end

      it "doesn't stage the address for changing" do
        expect(patient.pending_changes).not_to have_key("address_line_1")
        expect(patient.pending_changes).not_to have_key("address_line_2")
        expect(patient.pending_changes).not_to have_key("address_town")
        expect(patient.pending_changes).not_to have_key("address_postcode")
      end

      context "with a different postcode" do
        before { existing_patient.update!(address_postcode: "SW1A 1AB") }

        it "stages the entire address for changing" do
          expect(patient.pending_changes).to match(
            a_hash_including(
              "address_line_1" => nil,
              "address_line_2" => nil,
              "address_town" => nil,
              "address_postcode" => "SW1A 1AA"
            )
          )
        end
      end
    end

    context "with an existing patient without gender" do
      let(:data) { valid_data.merge("CHILD_GENDER" => "male") }

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "not_known",
          given_name: "Jimmy",
          date_of_birth: Date.new(2010, 1, 1)
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
      let(:data) { valid_data.merge("CHILD_GENDER" => "male") }

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          gender_code: "female",
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

      it "does not save the incoming gender" do
        expect(patient).to have_attributes(gender_code: "female")
      end

      it "does stage the gender differences" do
        expect(patient.pending_changes).to include("gender_code" => "male")
      end
    end

    context "with an existing patient without preferred names" do
      let(:data) do
        valid_data.merge(
          "CHILD_PREFERRED_FIRST_NAME" => "Jim",
          "CHILD_PREFERRED_LAST_NAME" => "Smithy"
        )
      end

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          given_name: "Jimmy",
          date_of_birth: Date.new(2010, 1, 1)
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
      let(:data) do
        valid_data.merge(
          "CHILD_PREFERRED_FIRST_NAME" => "Jim",
          "CHILD_PREFERRED_LAST_NAME" => "Smithy"
        )
      end

      let!(:existing_patient) do
        create(
          :patient,
          address_postcode: "SW1A 1AA",
          family_name: "Smith",
          given_name: "Jimmy",
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

    context "with an existing patient without address" do
      let(:data) do
        valid_data.merge(
          "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
          "CHILD_ADDRESS_LINE_2" => "",
          "CHILD_TOWN" => "London",
          "CHILD_POSTCODE" => "SW1A 1AA"
        )
      end

      let!(:existing_patient) do
        create(
          :patient,
          family_name: "Smith",
          given_name: "Jimmy",
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

    context "with an existing patient already with an address (with a different postcode)" do
      let(:data) do
        valid_data.merge(
          "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
          "CHILD_ADDRESS_LINE_2" => "",
          "CHILD_TOWN" => "London",
          "CHILD_POSTCODE" => "SW1A 1AA"
        )
      end

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

    context "with an existing patient already with an address (with the same postcode)" do
      let(:data) do
        valid_data.merge(
          "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
          "CHILD_ADDRESS_LINE_2" => "",
          "CHILD_TOWN" => "London",
          "CHILD_POSTCODE" => "SW1A 1AA"
        )
      end

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
          address_postcode: "SW1A 1AA",
          birth_academic_year: 2009,
          date_of_birth: Date.new(2010, 1, 1),
          registration: "8AB"
        )
      end

      it { should eq(existing_patient) }

      it "does save the incoming address" do
        expect(patient).to have_attributes(
          address_line_1: "10 Downing Street",
          address_line_2: "",
          address_town: "London",
          address_postcode: "SW1A 1AA"
        )
      end

      it "doesn't stage the address differences" do
        expect(patient.pending_changes).to be_empty
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
