# frozen_string_literal: true

describe BatchNumberValidator do
  subject(:model) { Validatable.new(number:) }

  before do
    stub_const("Validatable", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :number
      validates :number, batch_number: true
    end
  end

  shared_examples "can't be blank" do
    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:number]).to include("can't be blank")
    end
  end

  shared_examples "is invalid" do
    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:number]).to include("is invalid")
    end
  end

  context "with a nil value" do
    let(:number) { nil }

    it_behaves_like "can't be blank"
  end

  context "with an empty string" do
    let(:number) { "" }

    it_behaves_like "can't be blank"
  end

  context "with whitespace only" do
    let(:number) { "   " }

    it_behaves_like "can't be blank"
  end

  context "with a single character" do
    let(:number) { "A" }

    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:number]).to include(
        "is too short (minimum is 2 characters)"
      )
    end
  end

  context "with 101 characters" do
    let(:number) { "A" * 101 }

    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:number]).to include(
        "is too long (maximum is 100 characters)"
      )
    end
  end

  context "with special characters" do
    let(:number) { "Batch-123" }

    it_behaves_like "is invalid"
  end

  context "with spaces" do
    let(:number) { "Batch 123" }

    it_behaves_like "is invalid"
  end

  context "with underscores" do
    let(:number) { "Batch_123" }

    it_behaves_like "is invalid"
  end

  context "with dots" do
    let(:number) { "Batch.123" }

    it_behaves_like "is invalid"
  end

  context "with symbols" do
    let(:number) { "Batch@123" }

    it_behaves_like "is invalid"
  end

  context "with 2 characters" do
    let(:number) { "AB" }

    it { should be_valid }
  end

  context "with 100 characters" do
    let(:number) { "A" * 100 }

    it { should be_valid }
  end

  context "with alphanumeric characters" do
    let(:number) { "Batch123" }

    it { should be_valid }
  end

  context "with only letters" do
    let(:number) { "BatchNumber" }

    it { should be_valid }
  end

  context "with only numbers" do
    let(:number) { "123456" }

    it { should be_valid }
  end

  context "with mixed case" do
    let(:number) { "BaTcH123" }

    it { should be_valid }
  end
end
