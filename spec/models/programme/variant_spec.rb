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

    it "use variant type for the translation" do
      expect(I18n).to receive(:t).with(variant_type, scope: :programme_types)
      name
    end
  end

  describe "#name_in_sentence" do
    subject(:name_in_sentence) { programme_variant.name_in_sentence }

    it { should eq("MMRV") }
  end
end
