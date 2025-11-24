# frozen_string_literal: true

describe FHIRMapper::Vaccine do
  subject(:fhir_mapper) { described_class.new(vaccine) }

  let(:vaccine) do
    create(
      :vaccine,
      :injection,
      snomed_product_code: "183817183",
      snomed_product_term: "This is one great vaccine!!!",
      manufacturer: "Merck Sharp & Dohme",
      programme: Programme.hpv
    )
  end

  describe "#fhir_codeable_concept" do
    subject(:fhir_codeable_concept) { fhir_mapper.fhir_codeable_concept }

    it { should be_a(FHIR::CodeableConcept) }

    describe "its coding" do
      subject { fhir_codeable_concept.coding.first }

      its(:code) { should eq "183817183" }
      its(:display) { should eq "This is one great vaccine!!!" }
      its(:system) { should eq "http://snomed.info/sct" }
    end
  end

  describe "#fhir_manufacturer_reference" do
    subject { fhir_mapper.fhir_manufacturer_reference }

    it { should be_a FHIR::Reference }
    its(:display) { should eq "Merck Sharp & Dohme" }
  end

  describe "#fhir_procedure_coding" do
    subject(:fhir_procedure_coding) do
      fhir_mapper.fhir_procedure_coding(dose_sequence: nil)
    end

    it { should be_a(FHIR::CodeableConcept) }

    describe "its coding" do
      subject { fhir_procedure_coding.coding.first }

      its(:system) { should eq("http://snomed.info/sct") }
      its(:code) { should eq("761841000") }

      its(:display) do
        should eq(
                 "Administration of vaccine product containing only Human papillomavirus antigen (procedure)"
               )
      end
    end
  end

  describe "#from_fhir_record" do
    subject { described_class.from_fhir_record(fhir_record) }

    let(:vaccine) { Vaccine.find_by(snomed_product_code: "43207411000001105") }

    context "with a populated code" do
      let(:fhir_record) do
        FHIR.from_contents(file_fixture("/fhir/flu/fhir_record_full.json").read)
      end

      it { should eq(vaccine) }
    end

    context "with an unknown code" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("/fhir/flu/fhir_record_unknown_vaccine.json").read
        )
      end

      it { should be_nil }
    end

    context "with a null code" do
      let(:fhir_record) do
        FHIR.from_contents(file_fixture("/fhir/flu/fhir_record_gp.json").read)
      end

      it { should be_nil }
    end

    context "with no code at all" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("/fhir/flu/fhir_record_minimum_api_create.json").read
        )
      end

      it { should be_nil }
    end
  end
end
