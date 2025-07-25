# frozen_string_literal: true

describe FHIRMapper::Team do
  let(:ods_code) { "A9A5A" }

  describe ".fhir_reference" do
    it "returns a FHIR reference with the correct ODS code" do
      reference = described_class.fhir_reference(ods_code:)

      expect(reference.type).to eq "Organization"
      expect(
        reference.identifier.system
      ).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
      expect(reference.identifier.value).to eq ods_code
    end
  end

  describe "#fhir_reference" do
    let(:team) { Team.new(ods_code:) }
    let(:fhir_mapper) { described_class.new(team) }

    it "returns a FHIR reference with the correct ODS code" do
      reference = team.fhir_reference

      expect(reference.type).to eq "Organization"
      expect(
        reference.identifier.system
      ).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
      expect(reference.identifier.value).to eq ods_code
    end
  end
end
