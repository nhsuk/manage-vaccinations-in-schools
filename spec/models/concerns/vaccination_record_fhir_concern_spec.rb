# frozen_string_literal: true

describe VaccinationRecordFHIRConcern do
  include FHIRHelper

  let(:patient) { build(:patient) }
  let(:vaccination_record) { build(:vaccination_record, patient:) }
  # Normally we test this concern in isolation, but in this case it's bespoke to
  # the VaccinationRecord and has a lot of dependencies on it, so not really
  # worth it.
  let(:immunisation_record) { vaccination_record.to_fhir }

  describe "#to_fhir" do
    it "produces the correct record" do
      expect(immunisation_record.to_hash).to eq fhir_immunisation_json
    end
  end
end
