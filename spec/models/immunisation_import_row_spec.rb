# frozen_string_literal: true

require "rails_helper"

describe ImmunisationImport::Row, type: :model do
  subject(:immunisation_import_row) { described_class.new(row) }

  describe "validations" do
    context "with an empty row" do
      let(:row) { {} }

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
      let(:row) { { "VACCINATED" => "Yes" } }

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
      end
    end

    context "with an invalid organisation code" do
      let(:row) { { "ORGANISATION_CODE" => "this is too long" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "is too long (maximum is 5 characters)"
        )
      end
    end

    context "with valid fields" do
      let(:row) do
        {
          "ORGANISATION_CODE" => "abc",
          "VACCINATED" => "Yes",
          "ANATOMICAL_SITE" => "nasal"
        }
      end

      it { should be_valid }
    end
  end

  describe "#administered" do
    subject(:administered) { immunisation_import_row.administered }

    context "without a vaccinated field" do
      let(:row) { {} }

      it { should be_nil }
    end

    context "with positive vaccinated field" do
      let(:row) { { "VACCINATED" => "Yes" } }

      it { should be(true) }
    end

    context "with negative vaccinated field" do
      let(:row) { { "VACCINATED" => "No" } }

      it { should be(false) }
    end

    context "with an unknown vaccinated field" do
      let(:row) { { "VACCINATED" => "Other" } }

      it { should be_nil }
    end
  end

  describe "#delivery_method" do
    subject(:delivery_method) { immunisation_import_row.delivery_method }

    context "without an anatomical site" do
      let(:row) { {} }

      it { should be_nil }
    end

    context "with a nasal anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nasal_spray) }
    end

    context "with a non-nasal anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:intramuscular) }
    end

    context "with an unknown anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#delivery_site" do
    subject(:delivery_site) { immunisation_import_row.delivery_site }

    context "without an anatomical site" do
      let(:row) { {} }

      it { should be_nil }
    end

    context "with a left thigh anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:left_thigh) }
    end

    context "with a right thigh anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "right thigh" } }

      it { should eq(:right_thigh) }
    end

    context "with a left upper arm anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "left upper arm" } }

      it { should eq(:left_arm_upper_position) }
    end

    context "with a right upper arm anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "right upper arm" } }

      it { should eq(:right_arm_upper_position) }
    end

    context "with a left buttock anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "left buttock" } }

      it { should eq(:left_buttock) }
    end

    context "with a right buttock anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "right buttock" } }

      it { should eq(:right_buttock) }
    end

    context "with a nasal anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nose) }
    end

    context "with an unknown anatomical site" do
      let(:row) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#organisation_code" do
    subject(:organisation_code) { immunisation_import_row.organisation_code }

    context "without a value" do
      let(:row) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:row) { { "ORGANISATION_CODE" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#recorded_at" do
    let(:row) { {} }

    it { should_not be_nil }
  end
end
