# frozen_string_literal: true

describe FullNameFormatter do
  context "with no parts prefix" do
    subject { described_class.call(nameable, context:) }

    let(:nameable) { OpenStruct.new(given_name: "John", family_name: "Smith") }

    context "with internal context" do
      let(:context) { :internal }

      it { should eq("SMITH, John") }
    end

    context "with parents context" do
      let(:context) { :parents }

      it { should eq("John Smith") }
    end
  end

  context "with a parts prefix" do
    subject do
      described_class.call(nameable, context: :parents, parts_prefix: :parent)
    end

    let(:nameable) do
      OpenStruct.new(parent_given_name: "John", parent_family_name: "Smith")
    end

    it { should eq("John Smith") }
  end
end
