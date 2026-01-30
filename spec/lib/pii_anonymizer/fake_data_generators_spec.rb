# frozen_string_literal: true

require_relative "../../../app/lib/pii_anonymizer/fake_data_generators"

describe PIIAnonymizer::FakeDataGenerators do
  describe "Core data generation" do
    it "generates realistic names" do
      name = described_class.full_name
      expect(name).to match(/\A[A-Za-z]+\s[A-Za-z]+\z/)
    end

    it "generates unique emails with UK domains" do
      emails = 10.times.map { described_class.email }
      expect(emails.uniq.size).to eq(10)
      expect(emails.first).to match(/\A[^@\s]+@[^@\s]+\.(com|co\.uk|net)\z/)
    end

    it "generates valid UK phone numbers" do
      phone = described_class.uk_phone
      expect(phone).to match(/\A0[0-9]{10}\z/)
    end

    it "generates valid UK postcodes" do
      postcode = described_class.uk_postcode
      expect(postcode).to match(/\A[A-Z]{1,2}\d{1,2}[A-Z]?\s\d[A-Z]{2}\z/)
    end
  end

  describe "NHS number generation" do
    it "generates valid NHS numbers using NHSNumberValidator" do
      # Create a test model to use the validator
      test_model =
        Class.new do
          include ActiveModel::Model
          attr_accessor :nhs_number
          validates :nhs_number, nhs_number: true
        end

      10.times do
        nhs_number = described_class.nhs_number
        expect(nhs_number).to match(/\A[1-9]\d{9}\z/) # Format check

        # Use the actual NHSNumberValidator to validate
        model = test_model.new(nhs_number:)
        expect(model).to be_valid,
        "Generated NHS number #{nhs_number} should be valid according to NHSNumberValidator"
      end
    end

    it "generates unique NHS numbers" do
      numbers = 50.times.map { described_class.nhs_number }
      expect(numbers.uniq.size).to be > 45
    end
  end

  describe "Method calling" do
    it "calls PIIAnonymizer methods correctly" do
      result =
        described_class.call_faker_method(
          "PIIAnonymizer::FakeDataGenerators.first_name"
        )
      expect(result).to be_a(String)
      expect(result.length).to be > 2
    end

    it "calls Faker methods correctly" do
      result = described_class.call_faker_method("Faker::Name.first_name")
      expect(result).to be_a(String)
    end

    it "handles invalid methods gracefully" do
      result = described_class.call_faker_method("Invalid::Method.call")
      expect(result).to start_with("GENERATION_ERROR_")
    end
  end

  describe "BaseGenerator utilities" do
    let(:base_generator) { described_class::BaseGenerator }

    it "validates values correctly" do
      expect(base_generator.validate_value("test", max_length: 5)).to be true
      expect(
        base_generator.validate_value("toolong", max_length: 5)
      ).to be false
      expect(base_generator.validate_value("", min_length: 1)).to be false
    end

    it "generates high entropy random strings" do
      random = base_generator.high_entropy_random(10)
      expect(random.length).to eq(10)
      expect(random).to match(/\A[A-Za-z0-9]+\z/)
    end
  end
end
