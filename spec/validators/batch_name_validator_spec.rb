# frozen_string_literal: true

describe BatchNameValidator do
  subject(:model) { Validatable.new(name:) }

  before do
    stub_const("Validatable", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :name
      validates :name, batch_name: true
    end
  end

  shared_examples "can't be blank" do
    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:name]).to include("can't be blank")
    end
  end

  shared_examples "is invalid" do
    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:name]).to include("is invalid")
    end
  end

  context "with a nil value" do
    let(:name) { nil }

    it_behaves_like "can't be blank"
  end

  context "with an empty string" do
    let(:name) { "" }

    it_behaves_like "can't be blank"
  end

  context "with whitespace only" do
    let(:name) { "   " }

    it_behaves_like "can't be blank"
  end

  context "with a single character" do
    let(:name) { "A" }

    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:name]).to include(
        "is too short (minimum is 2 characters)"
      )
    end
  end

  context "with 101 characters" do
    let(:name) { "A" * 101 }

    it { should be_invalid }

    it "has the correct error message" do
      expect(model.valid?).to be false
      expect(model.errors[:name]).to include(
        "is too long (maximum is 100 characters)"
      )
    end
  end

  context "with special characters" do
    let(:name) { "Batch-123" }

    it_behaves_like "is invalid"
  end

  context "with spaces" do
    let(:name) { "Batch 123" }

    it_behaves_like "is invalid"
  end

  context "with underscores" do
    let(:name) { "Batch_123" }

    it_behaves_like "is invalid"
  end

  context "with dots" do
    let(:name) { "Batch.123" }

    it_behaves_like "is invalid"
  end

  context "with symbols" do
    let(:name) { "Batch@123" }

    it_behaves_like "is invalid"
  end

  context "with 2 characters" do
    let(:name) { "AB" }

    it { should be_valid }
  end

  context "with 100 characters" do
    let(:name) { "A" * 100 }

    it { should be_valid }
  end

  context "with alphanumeric characters" do
    let(:name) { "Batch123" }

    it { should be_valid }
  end

  context "with only letters" do
    let(:name) { "BatchName" }

    it { should be_valid }
  end

  context "with only numbers" do
    let(:name) { "123456" }

    it { should be_valid }
  end

  context "with mixed case" do
    let(:name) { "BaTcH123" }

    it { should be_valid }
  end
end
