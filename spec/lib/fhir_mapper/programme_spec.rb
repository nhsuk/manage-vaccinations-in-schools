# frozen_string_literal: true

describe FHIRMapper::Programme do
  let(:programme) { create(:programme, :hpv) }
  let(:mapper) { described_class.new(programme) }

  describe "#target_disease_coding" do
    subject(:target_disease_coding) { mapper.fhir_target_disease_coding }

    it "returns a FHIR CodeableConcept with the correct coding" do
      coding = target_disease_coding.coding.first
      expect(coding.system).to eq("http://snomed.info/sct")
      expect(coding.code).to eq("240532009")
      expect(coding.display).to eq("Human papillomavirus infection")
    end
  end
end
