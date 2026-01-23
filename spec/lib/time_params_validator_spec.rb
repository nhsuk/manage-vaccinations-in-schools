# frozen_string_literal: true

describe TimeParamsValidator do
  let(:dummy_class) do
    Class.new do
      attr_accessor :errors

      # Cannot find a better way to get the errors for a specific attribute,
      # replace as appropriate.
      def errors_for_attribute(attribute)
        errors.find_all { it.attribute == attribute }.map(&:type)
      end
    end
  end

  let(:dummy_object) do
    dummy_class.new.tap { |obj| obj.errors = ActiveModel::Errors.new(obj) }
  end
  let(:field_name) { "time_of_birth" }
  let(:validator) do
    described_class.new(field_name:, object: dummy_object, params:)
  end

  let(:hour) { "12" }
  let(:minute) { "30" }
  let(:second) { "45" }

  let(:params) do
    {
      "time_of_birth(4i)" => hour,
      "time_of_birth(5i)" => minute,
      "time_of_birth(6i)" => second
    }
  end

  describe "#time_params_as_struct" do
    context "when time params are provided" do
      let(:hour) { "12" }
      let(:minute) { "30" }
      let(:second) { "45" }

      it "returns a struct with hour, minute, and second" do
        struct = validator.time_params_as_struct

        expect(struct.hour).to eq("12")
        expect(struct.minute).to eq("30")
        expect(struct.second).to eq("45")
      end
    end
  end

  describe "#time_params_valid?" do
    context "with a valid time regardless of the model validations" do
      let(:hour) { "12" }
      let(:minute) { "30" }
      let(:second) { "45" }

      it "returns true" do
        expect(validator.time_params_valid?).to be true
      end
    end

    context "when all time params are blank" do
      let(:hour) { "" }
      let(:minute) { "" }
      let(:second) { "" }

      it "returns true" do
        expect(validator.time_params_valid?).to be true
      end
    end

    context "when second is missing" do
      let(:hour) { "12" }
      let(:minute) { "30" }
      let(:second) { "" }

      it "adds a missing_second error and returns false" do
        expect(validator.time_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:time_of_birth)).to include(
          :missing_second
        )
      end
    end

    context "when minute is missing" do
      let(:hour) { "12" }
      let(:minute) { "" }
      let(:second) { "45" }

      it "adds a missing_minute error and returns false" do
        expect(validator.time_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:time_of_birth)).to include(
          :missing_minute
        )
      end
    end

    context "when hour is missing" do
      let(:hour) { "" }
      let(:minute) { "30" }
      let(:second) { "45" }

      it "adds a missing_hour error and returns false" do
        expect(validator.time_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:time_of_birth)).to include(
          :missing_hour
        )
      end
    end

    context "when time is invalid" do
      let(:hour) { "25" }
      let(:minute) { "75" }
      let(:second) { "90" }

      it "adds a blank error and returns false" do
        expect(validator.time_params_valid?).to be false
        expect(dummy_object.errors_for_attribute(:time_of_birth)).to include(
          :blank
        )
      end
    end
  end
end
