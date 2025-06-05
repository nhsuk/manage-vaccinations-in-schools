#! frozen_string_literal: true

describe ProgrammeFHIRConcern do
  describe "#fhir_target_disease_coding" do
    let(:programme) { create(:programme, :hpv) }

    it "returns a FHIR CodeableConcept with the correct coding" do
      coding = programme.fhir_target_disease_coding.coding.first
      expect(coding.system).to eq("http://snomed.info/sct")
      expect(coding.code).to eq("240532009")
      expect(coding.display).to eq("Human papillomavirus infection (disorder)")
    end
  end
end
