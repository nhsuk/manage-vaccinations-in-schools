# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the VaccinationRecord and has a lot of dependencies on it, so not really
# worth it.
describe VaccinationRecordFHIRConcern do
  include FHIRHelper

  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:programme) { create(:programme, :hpv) }
  let(:patient_session) do
    create(:patient_session, programmes: [programme], organisation:)
  end
  let(:patient) { patient_session.patient }
  let(:session) { patient_session.session }
  let(:vaccination_outcome) { :administered }
  let(:vaccine) { vaccination_record.vaccine }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      performed_ods_code: organisation.ods_code,
      patient:,
      programme:,
      session:,
      vaccine: programme.active_vaccines.first,
      outcome: vaccination_outcome
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

    describe "status" do
      subject { immunisation_fhir.status }

      [
        { outcome: :administered, status: "completed" },
        { outcome: :refused, status: "not-done" },
        { outcome: :not_well, status: "not-done" },
        { outcome: :contraindications, status: "not-done" },
        { outcome: :already_had, status: "not-done" },
        { outcome: :absent_from_school, status: "not-done" },
        { outcome: :absent_from_session, status: "not-done" }
      ].each do |test|
        context "when the vaccination record outcome is #{test[:outcome]}" do
          let(:vaccination_outcome) { test[:outcome] }

          it { should eq test[:status] }
        end
      end
    end

    describe "vaccination procedure" do
      subject(:vaccination_procedure) do
        immunisation_fhir.extension.find do
          it.url ==
            "https://fhir.hl7.org.uk/StructureDefinition/Extension-UKCore-VaccinationProcedure"
        end
      end

      it { should be_present }
      it { should be_a FHIR::Extension }

      describe "coding" do
        subject { vaccination_procedure.valueCodeableConcept.coding.first }

        its(:system) { should eq "http://snomed.info/sct" }
        # TODO: This is a hardcoded value, need the correct code added
        its(:code) { should eq "1324681000000101" }

        # TODO: This is a hardcoded value, need the correct displayadded
        its(:display) do
          should eq "Administration of first dose of severe acute respiratory" \
                      " syndrome coronavirus 2 vaccine (procedure)"
        end
      end
    end

    describe "occurenceDateTime" do
      subject { immunisation_fhir.occurrenceDateTime }

      it { should eq vaccination_record.performed_at.iso8601 }
    end

    describe "recorded" do
      subject { immunisation_fhir.recorded }

      it { should eq vaccination_record.created_at.iso8601 }
    end

    describe "primarySource" do
      subject { immunisation_fhir.primarySource }

      context "when the vaccination record is recorded in service" do
        it { should be true }
      end

      context "when the vaccination record was imported and has no session" do
        let(:session) { nil }

        it { should be false }
      end
    end

    describe "manufacturer" do
      subject { immunisation_fhir.manufacturer }

      it { should eq vaccine.fhir_manufacturer_reference }
    end

    describe "location identifier" do
      subject { immunisation_fhir.location }

      it { should eq vaccination_record.location.fhir_reference }
    end

    describe "site" do
      subject(:site) { immunisation_fhir.site }

      it { should be_a FHIR::CodeableConcept }

      describe "site coding" do
        subject { site.coding.first }

        its(:code) { should eq "368208006" }
        its(:system) { should eq "http://snomed.info/sct" }
        its(:display) do
          should eq "Structure of left upper arm (body structure)"
        end
      end
    end

    describe "route" do
      subject(:route) { immunisation_fhir.route }

      it { should be_a FHIR::CodeableConcept }

      describe "route coding" do
        subject { route.coding.first }

        its(:code) { should eq "78421000" }
        its(:system) { should eq "http://snomed.info/sct" }
        its(:display) { should eq "Intramuscular route (qualifier value)" }
      end
    end

    describe "doseQuantity" do
      subject { immunisation_fhir.doseQuantity }

      it { should be_a FHIR::Quantity }
      its(:value) { should eq 0.5 } # Default dose quantity
      its(:unit) { should eq "milliliter" }
      its(:system) { should eq "http://unitsofmeasure.org" }
      its(:code) { should eq "ml" }
    end

    describe "performer" do
      subject(:performer) { immunisation_fhir.performer }

      describe "user actor" do
        subject { performer.find { |p| p.actor.type != "Organization" }.actor }

        its(:reference) { should eq user.fhir_id }
      end

      describe "organisation actor" do
        subject { performer.find { |p| p.actor.type == "Organization" }.actor }

        it { should eq organisation.fhir_reference }
      end
    end

    describe "reasonCode" do
      subject(:route) { immunisation_fhir.reasonCode.sole }

      it { should be_a FHIR::CodeableConcept }

      describe "reasonCode coding" do
        subject { route.coding.first }

        its(:code) { should eq "999004501000000104" }
        its(:system) { should eq "http://snomed.info/sct" }
      end
    end
  end
end
