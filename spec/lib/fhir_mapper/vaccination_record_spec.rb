# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the VaccinationRecord and has a lot of dependencies on it, so not really
# worth it.
describe FHIRMapper::VaccinationRecord do
  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation:, programmes: [programme]) }
  let(:programme) { create(:programme, :hpv) }
  let(:patient_session) do
    create(:patient_session, programmes: [programme], team:)
  end
  let(:patient) { patient_session.patient }
  let(:session) { patient_session.session }
  let(:vaccination_outcome) { :administered }
  let(:vaccine) { vaccination_record.vaccine }
  let(:nhs_immunisations_api_id) { nil }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      performed_ods_code: organisation.ods_code,
      patient:,
      programme:,
      session:,
      vaccine: programme.vaccines.first,
      outcome: vaccination_outcome,
      nhs_immunisations_api_id:
    )
  end
  let(:user) { vaccination_record.performed_by_user }

  describe "#fhir_record" do
    subject(:immunisation_fhir) { vaccination_record.fhir_record }

    describe "id" do
      subject { immunisation_fhir.id }

      context "when the vaccination record no UUID" do
        it { should be_nil }
      end

      context "when the vaccination record has a UUID" do
        let(:nhs_immunisations_api_id) { "1212-1212-1212-121212121212" }

        it { should eq "1212-1212-1212-121212121212" }
      end
    end

    describe "contained patient" do
      subject { immunisation_fhir.contained.find { it.id == "Patient1" } }

      it { should eq patient.fhir_record(reference_id: "Patient1") }
    end

    describe "patient reference" do
      subject { immunisation_fhir.patient.reference }

      it { should eq "#Patient1" }
    end

    describe "contained performing practitioner" do
      subject { immunisation_fhir.contained.find { it.id == "Practitioner1" } }

      it { should eq user.fhir_practitioner(reference_id: "Practitioner1") }
    end

    describe "performing practitioner" do
      subject do
        immunisation_fhir
          .performer
          .find { it.actor.type != "Organization" }
          .actor
          .reference
      end

      it { should eq "#Practitioner1" }
    end

    describe "identifier" do
      subject { immunisation_fhir.identifier.first }

      let(:mavis_system) do
        "http://manage-vaccinations-in-schools.nhs.uk/vaccination_records"
      end

      its(:value) { should eq vaccination_record.uuid }
      its(:system) { should eq mavis_system }
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
        its(:code) { should eq "761841000" }

        its(:display) do
          should eq "Administration of vaccine product containing only Human " \
                      "papillomavirus antigen (procedure)"
        end
      end
    end

    describe "occurenceDateTime" do
      subject { immunisation_fhir.occurrenceDateTime }

      it { should eq vaccination_record.performed_at.iso8601(3) }
    end

    describe "recorded" do
      subject { immunisation_fhir.recorded }

      it { should eq vaccination_record.created_at.iso8601(3) }
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

    describe "lotNumber" do
      subject { immunisation_fhir.lotNumber }

      it { should eq vaccination_record.batch.name }
    end

    describe "expirationDate" do
      subject { immunisation_fhir.expirationDate }

      it { should eq vaccination_record.batch.expiry.to_s }
    end

    describe "site" do
      subject(:site) { immunisation_fhir.site }

      it { should be_a FHIR::CodeableConcept }

      describe "site coding" do
        subject { site.coding.first }

        its(:code) { should eq "368208006" }
        its(:system) { should eq "http://snomed.info/sct" }

        its(:display) { should eq "Left upper arm structure" }
      end
    end

    describe "route" do
      subject(:route) { immunisation_fhir.route }

      it { should be_a FHIR::CodeableConcept }

      describe "route coding" do
        subject { route.coding.first }

        its(:code) { should eq "78421000" }
        its(:system) { should eq "http://snomed.info/sct" }
        its(:display) { should eq "Intramuscular" }
      end
    end

    describe "doseQuantity" do
      subject { immunisation_fhir.doseQuantity }

      it { should be_a FHIR::Quantity }
      its(:value) { should eq 0.5 } # Default dose quantity
      its(:unit) { should eq "ml" }
      its(:system) { should eq "http://snomed.info/sct" }
      its(:code) { should eq "258773002" }
    end

    describe "performer" do
      subject(:performer) { immunisation_fhir.performer }

      describe "user actor" do
        subject { performer.find { |p| p.actor.type != "Organization" }.actor }

        its(:reference) { should eq "#Practitioner1" }
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

        its(:code) { should eq "723620004" }
        its(:system) { should eq "http://snomed.info/sct" }
      end
    end

    describe "protocolApplied" do
      subject(:protocol_applied) { immunisation_fhir.protocolApplied.sole }

      it { should be_a FHIR::Immunization::ProtocolApplied }

      describe "targetDisease" do
        subject(:target_disease) { protocol_applied.targetDisease.sole }

        it { should eq programme.fhir_target_disease_coding }
      end

      describe "doseNumberPositiveInt" do
        subject(:dose_number) { protocol_applied.doseNumberPositiveInt }

        it { should eq 1 }
      end
    end
  end

  describe "#from_fhir_record" do
    subject(:record) do
      VaccinationRecord.from_fhir_record(fhir_immunization, patient:, team:)
    end

    around { |example| travel_to(Date.new(2025, 5, 20)) { example.run } }

    let(:programme) { create(:programme, :flu) }

    shared_examples "a mapped vaccination record (common fields)" do
      its(:persisted?) { should be false }

      # TODO: add source to vaccination_record

      its(:nhs_immunisations_api_id) do
        should eq "11112222-3333-4444-5555-666677779999"
      end

      its(:source) { pending("implementation") || raise } # should eq "nhs_immunisations_api" }
      its(:nhs_immunisations_api_synced_at) { should eq Time.current }
      its(:performed_at) { should eq Time.parse("2025-04-06T23:59:50.2+01:00") }
      its(:delivery_method) { should eq "intramuscular" }
      its(:delivery_site) { should eq "left_arm_upper_position" }
      its(:full_dose) { should be true }
      its(:outcome) { should eq "administered" }
      its(:location_name) { should eq "X99999" }
      its(:performed_ods_code) { should eq "B0C4P" }

      context "when the record is saved to the database" do
        before { record.save! }

        its(:persisted?) { should be true }
        its(:uuid) { should be_present }
      end
    end

    context "with a full fhir record" do
      let(:fhir_immunization) do
        FHIR.from_contents(
          File.read(
            Rails.root.join("spec/fixtures/fhir/from-fhir-record-full.json")
          )
        )
      end

      include_examples "a mapped vaccination record (common fields)"

      its(:performed_by_given_name) { should eq "Steph" }
      its(:performed_by_family_name) { should eq "Smith" }
      its(:batch) { should have_attributes(name: "4120Z001") }

      its(:vaccine) do
        should have_attributes(snomed_product_code: "43207411000001105")
      end
    end

    context "with a record that has an unknown vaccine" do
      let(:fhir_immunization) do
        FHIR.from_contents(
          File.read(
            Rails.root.join(
              "spec/fixtures/fhir/from-fhir-record-unknown-vaccine.json"
            )
          )
        )
      end

      include_examples "a mapped vaccination record (common fields)"

      it do
        expect(Sentry).to receive(:capture_exception).with(
          an_instance_of(FHIRMapper::VaccinationRecord::UnknownVaccine)
        )

        record
      end

      its(:vaccine) { should be_nil }
      its(:batch) { should be_nil }

      its(:notes) do
        should include(
                 "SNOMED product code: 43207411000001106",
                 "SNOMED description: Cell-based trivalent influenza vaccine",
                 "Batch number: 4120Z001",
                 "Batch expiry: 2026-07-02"
               )
      end
    end
  end
end
