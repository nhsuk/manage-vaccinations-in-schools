# frozen_string_literal: true

require "rails_helper"
require "date"

describe DateParamsValidator do
  let(:dummy_class) do
    Class.new do
      attr_accessor :errors

      # Cannot find a better way to get the errors for a specific attribute,
      # replace as appropriate.
      def errors_for_attribute(attribute)
        errors.find_all { |e| e.attribute == attribute }.map(&:type)
      end
    end
  end

  let(:dummy_object) do
    dummy_class.new.tap { |obj| obj.errors = ActiveModel::Errors.new(obj) }
  end
  let(:field_name) { "date_of_birth" }
  let(:validator) do
    described_class.new(field_name:, object: dummy_object, params:)
  end

  let(:year) { "2012" }
  let(:month) { "12" }
  let(:day) { "24" }

  let(:params) do
    {
      "date_of_birth(1i)" => year,
      "date_of_birth(2i)" => month,
      "date_of_birth(3i)" => day
    }
  end

  describe "#date_params_as_struct" do
    context "when date params are provided" do
      let(:year) { "2000" }
      let(:month) { "1" }
      let(:day) { "20" }

      it "returns a struct with year, month, and day" do
        struct = validator.date_params_as_struct

        expect(struct.year).to eq("2000")
        expect(struct.month).to eq("1")
        expect(struct.day).to eq("20")
      end
    end
  end

  describe "#date_params_valid?" do
    context "with a valid date regardless of the model validations" do
      let(:year) { "1972" }
      let(:month) { "4" }
      let(:day) { "3" }

      it "returns true" do
        expect(validator.date_params_valid?).to be true
      end
    end

    context "when all date params are blank" do
      let(:year) { "" }
      let(:month) { "" }
      let(:day) { "" }

      it "returns true" do
        expect(validator.date_params_valid?).to be true
      end
    end

    context "when day is missing" do
      let(:year) { "2000" }
      let(:month) { "1" }
      let(:day) { "" }

      it "adds a missing_day error and returns false" do
        expect(validator.date_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:date_of_birth)).to include(
          :missing_day
        )
      end
    end

    context "when month is missing" do
      let(:year) { "2000" }
      let(:month) { "" }
      let(:day) { "20" }

      it "adds a missing_month error and returns false" do
        expect(validator.date_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:date_of_birth)).to include(
          :missing_month
        )
      end
    end

    context "when year is missing" do
      let(:year) { "" }
      let(:month) { "1" }
      let(:day) { "20" }

      it "adds a missing_year error and returns false" do
        expect(validator.date_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:date_of_birth)).to include(
          :missing_year
        )
      end
    end

    context "when year is less than 1000" do
      let(:year) { "860" }
      let(:month) { "1" }
      let(:day) { "20" }

      it "adds a missing_year error and returns false" do
        expect(validator.date_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:date_of_birth)).to include(
          :missing_year
        )
      end
    end

    context "when date is invalid" do
      let(:year) { "2000" }
      let(:month) { "2" }
      let(:day) { "30" }

      it "adds a blank error and returns false" do
        expect(validator.date_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:date_of_birth)).to include(
          :blank
        )
      end
    end
  end
end
