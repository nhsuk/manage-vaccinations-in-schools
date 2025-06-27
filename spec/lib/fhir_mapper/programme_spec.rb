# frozen_string_literal: true

RSpec.describe FHIRMapper::Programme do
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

  describe "#procedure_coding" do
    subject(:procedure_coding) { mapper.fhir_procedure_coding }

    it "returns a FHIR CodeableConcept with the correct coding" do
      coding = procedure_coding.coding.first
      expect(coding.system).to eq("http://snomed.info/sct")
      expect(coding.code).to eq("761841000")
      expect(coding.display).to eq(
        "Administration of vaccine product containing only Human papillomavirus antigen (procedure)"
      )
    end
  end
end
