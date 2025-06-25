# frozen_string_literal: true

describe FHIRMapper::Vaccine do
  subject(:fhir_mapper) { described_class.new(vaccine) }

  let(:vaccine) do
    create(
      :vaccine,
      snomed_product_code: "183817183",
      snomed_product_term: "This is one great vaccine!!!",
      manufacturer: "Merck Sharp & Dohme"
    )
  end

  describe "#fhir_codeable_concept" do
    subject(:vaccine_codeable_concept) { fhir_mapper.fhir_codeable_concept }

    describe "it's coding" do
      subject { vaccine_codeable_concept.coding.first }

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
end
