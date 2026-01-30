# frozen_string_literal: true

describe FHIRMapper::Programme do
  let(:programme) { Programme.hpv }
  let(:mapper) { described_class.new(programme) }

  describe "#target_disease_coding" do
    subject(:target_disease_coding) { mapper.fhir_target_disease_coding }

    shared_examples "maps target disease coding correctly" do |pt|
      let(:programme) { Programme.public_send(pt) }

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

  describe "#from_fhir_record" do
    subject(:programme) { described_class.from_fhir_record(fhir_record) }

    context "for a flu record" do
      let(:fhir_record) do
        FHIR.from_contents(file_fixture("fhir/flu/fhir_record_full.json").read)
      end

      it { should be Programme.flu }

      it { should be_a Programme }
    end

    context "for an hpv record" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("fhir/hpv/fhir_record_from_mavis.json").read
        )
      end

      it { should be Programme.hpv }

      it { should be_a Programme }
    end

    context "for a menacwy record" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("fhir/menacwy/fhir_record_from_mavis.json").read
        )
      end

      it { should be Programme.menacwy }

      it { should be_a Programme }
    end

    context "for a td_ipv record" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("fhir/td_ipv/fhir_record_from_mavis.json").read
        )
      end

      it { should be Programme.td_ipv }

      it { should be_a Programme }
    end

    context "for a mmr record" do
      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("fhir/mmr/fhir_record_from_mavis.json").read
        )
      end

      it do
        expect(programme).to eq Programme.mmr.variant_for(
             disease_types: Programme::Variant::DISEASE_TYPES.fetch("mmr")
           )
      end

      it { should be_a Programme::Variant }
    end

    context "for a mmrv record" do
      before { Flipper.enable(:mmrv) }

      let(:fhir_record) do
        FHIR.from_contents(
          file_fixture("fhir/mmrv/fhir_record_from_mavis.json").read
        )
      end

      it do
        expect(programme).to eq Programme.mmr.variant_for(
             disease_types: Programme::Variant::DISEASE_TYPES.fetch("mmrv")
           )
      end

      it { should be_a Programme::Variant }
    end
  end
end
