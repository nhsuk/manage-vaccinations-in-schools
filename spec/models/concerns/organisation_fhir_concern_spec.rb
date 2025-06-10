# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the VaccinationRecord and has a lot of dependencies on it, so not really
# worth it.
describe OrganisationFHIRConcern do
  let(:ods_code) { "A9A5A" }

  describe ".fhir_reference" do
    it "returns a FHIR reference with the correct ODS code" do
      reference = Organisation.fhir_reference(ods_code:)

      expect(reference.type).to eq "Organization"
      expect(
        reference.identifier.system
      ).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
      expect(reference.identifier.value).to eq ods_code
    end
  end

  describe "#fhir_reference" do
    subject(:organisation) { Organisation.new(ods_code:) }

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
