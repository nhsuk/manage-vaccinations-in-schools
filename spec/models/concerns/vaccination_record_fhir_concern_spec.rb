# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the VaccinationRecord and has a lot of dependencies on it, so not really
# worth it.
describe VaccinationRecordFHIRConcern do
  include FHIRHelper

  let(:patient) { create(:patient) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:programme) { create(:programme, :hpv) }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      performed_ods_code: organisation.ods_code,
      patient:,
      programme:,
      vaccine: programme.active_vaccines.first
    )
  end
  let(:user) { vaccination_record.performed_by_user }

  describe "#to_fhir" do
    subject(:immunisation_fhir) { vaccination_record.to_fhir }

    # it "produces the correct record" do
    #   expect(immunisation_fhir.to_hash).to eq fhir_immunisation_json(patient:)
    # end

    describe "contained patient" do
      subject { immunisation_fhir.contained.find { it.id == patient.fhir_id } }

      it { should eq patient.to_fhir }
    end

    describe "patient reference" do
      subject { immunisation_fhir.patient.reference }

      it { should eq patient.fhir_id }
    end

    describe "contained performing practitioner" do
      subject { immunisation_fhir.contained.find { it.id == patient.fhir_id } }

      it { should eq patient.to_fhir }
    end

    describe "performing practitioner" do
      subject do
        immunisation_fhir
          .performer
          .find { it.actor.type != "Organization" }
          .actor
          .reference
      end

      it { should eq user.fhir_id }
    end

    describe "identifier" do
      subject { immunisation_fhir.identifier.first }

      let(:mavis_system) do
        "http://manage-vaccinations-in-schools.nhs.uk/vaccination_records"
      end

      its(:value) { should eq vaccination_record.uuid }
      its(:system) { should eq mavis_system }
    end

    describe "status" do
      subject { immunisation_fhir.status }

      it { should eq "completed" }
    end

    describe "vaccine code" do
      subject { immunisation_fhir.vaccineCode.coding.first }

      its(:code) { should eq vaccination_record.vaccine.snomed_product_code }
      its(:display) { should eq vaccination_record.vaccine.snomed_product_term }
      its(:system) { should eq "http://snomed.info/sct" }
    end

    describe "performing organisation" do
      subject do
        immunisation_fhir
          .performer
          .find { it.actor.type == "Organization" }
          .actor
      end

      let(:organisation_fhir_reference) do
        Organisation.fhir_reference(
          ods_code: vaccination_record.performed_ods_code
        )
      end

      it { should eq organisation_fhir_reference }
    end
  end
end
