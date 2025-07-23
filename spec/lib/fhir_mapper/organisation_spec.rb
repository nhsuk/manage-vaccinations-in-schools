# frozen_string_literal: true

describe FHIRMapper::Organisation do
  let(:ods_code) { "A9A5A" }

  describe "#fhir_reference" do
    let(:organisation) { Organisation.new(ods_code:) }
    let(:fhir_mapper) { described_class.new(organisation) }

    it "returns a FHIR reference with the correct ODS code" do
      reference = organisation.fhir_reference

      expect(reference.type).to eq "Organization"
      expect(
        reference.identifier.system
      ).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
      expect(reference.identifier.value).to eq ods_code
    end
  end
end
