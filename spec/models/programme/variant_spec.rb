# frozen_string_literal: true

describe Programme::Variant do
  subject(:programme_variant) { described_class.new(programme, variant_type:) }

  let(:programme) { Programme.mmr }
  let(:variant_type) { "mmrv" }

  describe "#initialize" do
    it "wraps the base programme" do
      expect(programme_variant.__getobj__).to eq(programme)
    end
  end

  describe "#translation_key" do
    subject { programme_variant.translation_key }

    it { should eq(variant_type) }
  end

  describe "#name" do
    subject(:name) { programme_variant.name }

    context "with MMR variant type" do
      let(:variant_type) { "mmr" }

      it { should eq("MMR") }
    end

    context "with MMRV variant type" do
      let(:variant_type) { "mmrv" }

      it { should eq("MMRV") }
    end
  end

  describe "#name_in_sentence" do
    subject(:name_in_sentence) { programme_variant.name_in_sentence }

    it { should eq("MMRV") }
  end
end
