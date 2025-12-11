# frozen_string_literal: true

describe ProgrammeVariant do
  subject(:programme_variant) { described_class.new(programme, variant_type:) }

  let(:programme) { Programme.mmr }
  let(:variant_type) { "mmrv" }

  describe "#initialize" do
    it "wraps the base programme" do
      expect(programme_variant.__getobj__).to eq(programme)
    end
  end

  describe "#translation_key" do
    it "returns the variant type" do
      expect(programme_variant.translation_key).to eq(variant_type)
    end
  end

  describe "#name" do
    it "use variant type for the translation" do
      expect(I18n).to receive(:t).with(variant_type, scope: :programme_types)
      programme_variant.name
    end
  end

  describe "#name_in_sentence" do
    it "returns the variant name" do
      expect(programme_variant.name_in_sentence).to eq("MMRV")
    end
  end

  describe "#vaccines" do
    it "queries vaccines with the programme variant and distinguishing diseases" do
      expect(Vaccine).to receive(:where_programme).with(
        programme_variant,
        %w[measles mumps rubella varicella]
      )

      programme_variant.vaccines
    end
  end
end
