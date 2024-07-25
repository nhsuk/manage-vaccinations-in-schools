# frozen_string_literal: true

require "rails_helper"

describe ImmunisationImport::Row, type: :model do
  subject(:immunisation_import_row) do
    described_class.new(data:, campaign:, team:)
  end

  let(:campaign) { create(:campaign) }
  let(:team) { create(:team, ods_code: "abc") }

  describe "validations" do
    context "with an empty row" do
      let(:data) { {} }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:administered]).to include(
          "is required but missing"
        )
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "is required but missing"
        )
      end
    end

    context "when missing fields" do
      let(:data) { { "VACCINATED" => "Yes" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:delivery_site]).to include(
          "is required but missing"
        )
        expect(immunisation_import_row.errors[:delivery_method]).to include(
          "is required but missing"
        )
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "is required but missing"
        )
        expect(immunisation_import_row.errors[:patient_gender_code]).to include(
          "is required but missing"
        )
        expect(immunisation_import_row.errors[:patient_postcode]).to include(
          "is required but missing"
        )
      end
    end

    context "with an invalid organisation code" do
      let(:data) { { "ORGANISATION_CODE" => "this is too long" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "is too long (maximum is 5 characters)"
        )
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "must be equal to abc"
        )
      end
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "ABC DEF" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_postcode]).to include(
          /Enter a valid postcode/
        )
      end
    end

    context "with an invalid gender code" do
      let(:data) { { "PERSON_GENDER_CODE" => "10" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_postcode]).to include(
          /Enter a valid postcode/
        )
      end
    end

    context "with an invalid session date" do
      let(:data) { { "DATE_OF_VACCINATION" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
      end
    end

    context "with an invalid patient date of birth" do
      let(:data) { { "PERSON_DOB" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
      end
    end

    context "with valid fields" do
      let(:data) do
        {
          "ORGANISATION_CODE" => "abc",
          "VACCINATED" => "Yes",
          "ANATOMICAL_SITE" => "nasal",
          "SCHOOL_NAME" => "Hogwarts",
          "SCHOOL_URN" => "123456",
          "PERSON_FORENAME" => "Harry",
          "PERSON_SURNAME" => "Potter",
          "PERSON_DOB" => "20120101",
          "PERSON_POSTCODE" => "SW1A 1AA",
          "PERSON_GENDER_CODE" => "Male",
          "NHS_NUMBER" => "1234567890",
          "DATE_OF_VACCINATION" => "20240101"
        }
      end

      it { should be_valid }
    end
  end

  describe "#administered" do
    subject(:administered) { immunisation_import_row.administered }

    context "without a vaccinated field" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with positive vaccinated field" do
      let(:data) { { "VACCINATED" => "Yes" } }

      it { should be(true) }
    end

    context "with negative vaccinated field" do
      let(:data) { { "VACCINATED" => "No" } }

      it { should be(false) }
    end

    context "with an unknown vaccinated field" do
      let(:data) { { "VACCINATED" => "Other" } }

      it { should be_nil }
    end
  end

  describe "#reason" do
    subject(:reason) { immunisation_import_row.reason }

    context "without a reason" do
      let(:data) { { "VACCINATED" => "No" } }

      it { expect(immunisation_import_row).to be_invalid }
    end

    context "without an unknown reason" do
      let(:data) do
        { "VACCINATED" => "No", "REASON_NOT_VACCINATED" => "Unknown" }
      end

      it { expect(immunisation_import_row).to be_invalid }
    end

    context "with a reason" do
      let(:data) do
        { "VACCINATED" => "No", "REASON_NOT_VACCINATED" => "Did Not Attend" }
      end

      it { should eq(:absent_from_session) }
    end
  end

  describe "#delivery_method" do
    subject(:delivery_method) { immunisation_import_row.delivery_method }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nasal_spray) }
    end

    context "with a non-nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:intramuscular) }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#delivery_site" do
    subject(:delivery_site) { immunisation_import_row.delivery_site }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a left thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:left_thigh) }
    end

    context "with a right thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right thigh" } }

      it { should eq(:right_thigh) }
    end

    context "with a left upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left upper arm" } }

      it { should eq(:left_arm_upper_position) }
    end

    context "with a right upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right upper arm" } }

      it { should eq(:right_arm_upper_position) }
    end

    context "with a left buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left buttock" } }

      it { should eq(:left_buttock) }
    end

    context "with a right buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right buttock" } }

      it { should eq(:right_buttock) }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nose) }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#organisation_code" do
    subject(:organisation_code) { immunisation_import_row.organisation_code }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "ORGANISATION_CODE" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#patient_gender_code" do
    subject(:patient_gender_code) do
      immunisation_import_row.patient_gender_code
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an unknown value" do
      let(:data) { { "PERSON_GENDER_CODE" => "unknown" } }

      it { should be_nil }
    end

    context "with a 'not known' value" do
      let(:data) { { "PERSON_GENDER_CODE" => "Not Known" } }

      it { should eq(0) }
    end

    context "with a 'male' value" do
      let(:data) { { "PERSON_GENDER_CODE" => "Male" } }

      it { should eq(1) }
    end

    context "with a 'female' value" do
      let(:data) { { "PERSON_GENDER_CODE" => "Female" } }

      it { should eq(2) }
    end

    context "with a 'not specified' value" do
      let(:data) { { "PERSON_GENDER_CODE" => "Not Specified" } }

      it { should eq(9) }
    end
  end

  describe "#patient_postcode" do
    subject(:patient_postcode) { immunisation_import_row.patient_postcode }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "abc" } }

      it { should eq("abc") }
    end

    context "with a valid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "SW1 1AA" } }

      it { should eq("SW1 1AA") }
    end

    context "with a valid unformatted postcode" do
      let(:data) { { "PERSON_POSTCODE" => "sw11aa" } }

      it { should eq("SW1 1AA") }
    end
  end

  describe "#recorded_at" do
    let(:data) { {} }

    it { should_not be_nil }
  end
end
