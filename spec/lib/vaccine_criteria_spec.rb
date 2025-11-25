# frozen_string_literal: true

describe VaccineCriteria do
  subject(:vaccine_criteria) do
    described_class.new(programme:, vaccine_methods:, without_gelatine:)
  end

  describe "#from_param" do
    subject(:from_param) { described_class.from_param(param) }

    context "with 'flu_injection_without_gelatine'" do
      let(:param) { "flu_injection_without_gelatine" }

      its(:programme) { should be_flu }
      its(:vaccine_methods) { should eq([Vaccine::METHOD_INJECTION]) }
      its(:without_gelatine) { should be(true) }
    end

    context "with 'flu_nasal_injection'" do
      let(:param) { "flu_nasal_injection" }

      its(:programme) { should be_flu }

      its(:vaccine_methods) do
        should eq([Vaccine::METHOD_NASAL, Vaccine::METHOD_INJECTION])
      end

      its(:without_gelatine) { should be(false) }
    end

    context "with 'mmr_injection'" do
      let(:param) { "mmr_injection" }

      its(:programme) { should be_mmr }
      its(:vaccine_methods) { should eq([Vaccine::METHOD_INJECTION]) }
      its(:without_gelatine) { should be(false) }
    end
  end

  describe "#to_param" do
    subject(:to_param) { vaccine_criteria.to_param }

    context "for flu programme" do
      let(:programme) { Programme.flu }

      context "injection only" do
        let(:without_gelatine) { true }
        let(:vaccine_methods) { [Vaccine::METHOD_INJECTION] }

        it { should eq("flu_injection_without_gelatine") }
      end

      context "nasal only" do
        let(:without_gelatine) { false }
        let(:vaccine_methods) { [Vaccine::METHOD_NASAL] }

        it { should eq("flu_nasal") }
      end

      context "nasal or injection" do
        let(:without_gelatine) { false }
        let(:vaccine_methods) do
          [Vaccine::METHOD_NASAL, Vaccine::METHOD_INJECTION]
        end

        it { should eq("flu_nasal_injection") }
      end
    end

    context "for MMR programme" do
      let(:programme) { Programme.mmr }

      context "without gelatine" do
        let(:without_gelatine) { true }
        let(:vaccine_methods) { [Vaccine::METHOD_INJECTION] }

        it { should eq("mmr_injection_without_gelatine") }
      end

      context "with or without gelatine" do
        let(:without_gelatine) { false }
        let(:vaccine_methods) { [Vaccine::METHOD_INJECTION] }

        it { should eq("mmr_injection") }
      end
    end

    context "for any other programme" do
      let(:programme) { Programme.find(%w[hpv menacwy td_ipv].sample) }

      let(:without_gelatine) { false }
      let(:vaccine_methods) { [Vaccine::METHOD_INJECTION] }

      it { should eq("#{programme.type}_injection") }
    end
  end
end
