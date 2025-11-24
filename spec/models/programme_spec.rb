# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#

describe Programme do
  subject(:programme) { described_class.sample }

  it_behaves_like "a Flipper actor"

  describe "#find" do
    subject(:find) { described_class.find(type) }

    context "with a known type" do
      let(:type) { Programme::TYPES.sample }

      it { should_not be_nil }
    end

    context "with an unknown type" do
      let(:type) { "unknown" }

      it "raises an error" do
        expect { find }.to raise_error(Programme::InvalidType)
      end
    end
  end

  describe "#name" do
    subject { programme.name }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should eq("Flu") }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should eq("HPV") }
    end
  end

  describe "#name_in_sentence" do
    subject(:name) { programme.name_in_sentence }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should eq("flu") }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should eq("HPV") }
    end
  end

  describe "#seasonal?" do
    subject { programme.seasonal? }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should be(true) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should be(false) }
    end

    context "with an MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should be(false) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should be(false) }
    end
  end

  describe "#supports_delegation?" do
    subject { programme.supports_delegation? }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should be(true) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should be(false) }
    end

    context "with an MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should be(false) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should be(false) }
    end
  end

  describe "#triage_on_vaccination_history?" do
    subject { programme.triage_on_vaccination_history? }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should be(false) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should be(false) }
    end

    context "with an MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should be(true) }
    end

    context "with an MMR programme" do
      let(:programme) { described_class.mmr }

      it { should be(false) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should be(true) }
    end
  end

  describe "#default_year_groups" do
    subject { programme.default_year_groups }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should eq([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should eq([8, 9, 10, 11]) }
    end

    context "with a MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should eq([9, 10, 11]) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should eq([9, 10, 11]) }
    end
  end

  describe "#vaccine_methods" do
    subject { programme.vaccine_methods }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should contain_exactly("injection", "nasal") }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should contain_exactly("injection") }
    end
  end

  describe "#vaccine_may_contain_gelatine?" do
    subject { programme.vaccine_may_contain_gelatine? }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should be(true) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should be(false) }
    end

    context "with an MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should be(false) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should be(false) }
    end
  end

  describe "#default_dose_sequence" do
    subject(:default_dose_sequence) { programme.default_dose_sequence }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should eq(1) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should eq(1) }
    end

    context "with a MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should be_nil }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should be_nil }
    end
  end

  describe "#maximum_dose_sequence" do
    subject(:maximum_dose_sequence) { programme.maximum_dose_sequence }

    context "with a flu programme" do
      let(:programme) { described_class.flu }

      it { should eq(2) }
    end

    context "with an HPV programme" do
      let(:programme) { described_class.hpv }

      it { should eq(3) }
    end

    context "with a MenACWY programme" do
      let(:programme) { described_class.menacwy }

      it { should eq(3) }
    end

    context "with an Td/IPV programme" do
      let(:programme) { described_class.td_ipv }

      it { should eq(5) }
    end
  end

  describe ".find" do
    context "when programme is MMR and MMRV support iss enabled" do
      subject(:programme) { described_class.mmr }

      before { Flipper.enable(:mmrv) }

      it "returns a Programme" do
        expect(described_class.find("mmr")).to be_a(described_class)
      end

      context "when patient was born after 1 January 2020" do
        let(:date_of_birth) { Programme::MIN_MMRV_ELIGIBILITY_DATE + 1.month }
        let(:patient) { create(:patient, date_of_birth:) }

        it "returns a ProgrammeVariant with mmrv variant type" do
          result = described_class.find("mmr", patient:)

          expect(result).to be_a(ProgrammeVariant)
          expect(result.send(:variant_type)).to eq("mmrv")
        end
      end
    end
  end
end
