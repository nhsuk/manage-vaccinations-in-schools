# frozen_string_literal: true

describe NHSNumberValidator do
  subject(:model) { Validatable.new(nhs_number:) }

  before do
    stub_const("Validatable", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :nhs_number
      validates :nhs_number, nhs_number: true
    end

    stub_const("ValidatableAllowNil", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :nhs_number
      validates :nhs_number, nhs_number: { allow_nil: true }
    end

    stub_const("ValidatableAllowBlank", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :nhs_number
      validates :nhs_number, nhs_number: { allow_blank: true }
    end
  end

  context "with a nil NHS number" do
    let(:nhs_number) { nil }

    it { should be_invalid }
  end

  context "with a blank NHS number" do
    let(:nhs_number) { "" }

    it { should be_invalid }
  end

  context "with an NHS number that's too short" do
    let(:nhs_number) { "abc" }

    it { should be_invalid }
  end

  context "with an invalid NHS number" do
    let(:nhs_number) { "TP12345678" }

    it { should be_invalid }
  end

  context "with a valid NHS number" do
    let(:nhs_number) { "0123456789" }

    it { should be_valid }
  end

  context "when allowing nil values" do
    subject(:model) { ValidatableAllowNil.new(nhs_number:) }

    let(:nhs_number) { nil }

    it { should be_valid }
  end

  context "when allowing blank values" do
    subject(:model) { ValidatableAllowBlank.new(nhs_number:) }

    let(:nhs_number) { "" }

    it { should be_valid }
  end
end
