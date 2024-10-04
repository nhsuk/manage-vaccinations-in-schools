# frozen_string_literal: true

describe PostcodeValidator do
  subject(:model) { Validatable.new(postcode:) }

  before do
    stub_const("Validatable", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :postcode
      validates :postcode, postcode: true
    end

    stub_const("ValidatableAllowNil", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :postcode
      validates :postcode, postcode: { allow_nil: true }
    end

    stub_const("ValidatableAllowBlank", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :postcode
      validates :postcode, postcode: { allow_blank: true }
    end
  end

  context "with a nil postcode" do
    let(:postcode) { nil }

    it { should be_invalid }
  end

  context "with a blank postcode" do
    let(:postcode) { "" }

    it { should be_invalid }
  end

  context "with an invalid postcode" do
    let(:postcode) { "abc" }

    it { should be_invalid }
  end

  context "with a valid postcode" do
    let(:postcode) { "SW1A 1AA" }

    it { should be_valid }
  end

  context "when allowing nil values" do
    subject(:model) { ValidatableAllowNil.new(postcode:) }

    let(:postcode) { nil }

    it { should be_valid }
  end

  context "when allowing blank values" do
    subject(:model) { ValidatableAllowBlank.new(postcode:) }

    let(:postcode) { "" }

    it { should be_valid }
  end
end
