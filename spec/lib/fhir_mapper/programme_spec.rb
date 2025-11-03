# frozen_string_literal: true

describe FHIRMapper::Programme do
  # TODO: make this test all programmes
  let(:programme) { create(:programme, :mmr) }
  let(:mapper) { described_class.new(programme) }

  describe "#target_disease_coding" do
    subject(:target_disease_coding) { mapper.fhir_target_disease_coding }

    it "returns a FHIR CodeableConcept with the correct coding" do
      codings = target_disease_coding.map { it.coding.first }
      expect(codings.map(&:system)).to eq(["http://snomed.info/sct"] * 3)
      expect(codings.map(&:code)).to eq(%w[14189004 36989005 36653000])
      expect(codings.map(&:display)).to eq(%w[Measles Mumps Rubella])
    end
  end
end
