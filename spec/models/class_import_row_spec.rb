# frozen_string_literal: true

describe ClassImportRow do
  subject(:class_import_row) do
    described_class.new(
      data: data_as_csv_row,
      session:,
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
  let(:organisation) { create(:organisation, programmes:) }
  let(:school) { create(:school, organisation:) }
  let(:session) do
    create(:session, organisation:, programmes:, location: school)
  end

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
  end

  describe "#to_parent_relationships" do
    subject(:parent_relationships) do
      class_import_row.to_parent_relationships(
        class_import_row.to_parents,
        patient
      )
    end

    let(:patient) do
      PatientImporter::DataProcessor.call(class_import_row.to_h).patient
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
