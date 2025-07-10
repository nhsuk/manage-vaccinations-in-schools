# frozen_string_literal: true

describe CohortImportRow do
  subject(:cohort_import_row) do
    described_class.new(data: data_as_csv_row, organisation:)
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
  let(:organisation) { create(:organisation, programmes: [programme]) }

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

  before { create(:school, urn: "123456") }

  describe "validations" do
    let(:data) { valid_data }

    it { should be_valid }

    context "when date of birth is outside the programme year group" do
      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => "1990-01-01") }

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
            "and you believe it’s valid, contact our support organisation."
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
  end

  describe "#to_school_move" do
    subject(:school_move) { cohort_import_row.to_school_move(patient) }

    let(:data) { valid_data }

    let(:patient) { create(:patient, school: create(:school)) }

    it { should_not be_nil }

    describe "#school" do
      subject(:school) { school_move.school }

      context "with a school location" do
        let(:school_urn) { "123456" }

        it { should eq(Location.first) }
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
      subject(:home_educated) { school_move.home_educated }

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
          organisation: nil,
          school: Location.first
        )
      end

      let(:data) { valid_data }

      it { should_not be_nil }
    end
  end
end
