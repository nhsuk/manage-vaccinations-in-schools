# frozen_string_literal: true

describe FHIRMapper::Programme do
  let(:mapper) { described_class.new(programme) }

  describe "#target_disease_coding" do
    subject(:target_disease_coding) { mapper.fhir_target_disease_coding }

    shared_examples "maps target disease coding correctly" do |pt|
      let(:programme) { CachedProgramme.public_send(pt) }

      it "returns a FHIR CodeableConcept with the correct coding" do
        codings = target_disease_coding.map { it.coding.first }

        expect(codings.map(&:system)).to eq(
          ["http://snomed.info/sct"] * codings.count
        )
        expect(codings.map(&:code)).to match_array(
          ::Programme::SNOMED_TARGET_DISEASE_CODES.fetch(pt)
        )
        expect(codings.map(&:display)).to eq(
          ::Programme::SNOMED_TARGET_DISEASE_TERMS.fetch(pt)
        )
      end
    end

    ::Programme::SNOMED_TARGET_DISEASE_CODES.each_key do |programme_type|
      context "for each programme type" do
        include_examples "maps target disease coding correctly", programme_type
      end
    end
  end
end
