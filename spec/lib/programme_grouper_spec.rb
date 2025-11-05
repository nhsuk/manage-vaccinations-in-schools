# frozen_string_literal: true

describe ProgrammeGrouper do
  describe "#call" do
    subject(:call) { described_class.call(programmes) }

    let(:hpv) { CachedProgramme.hpv }
    let(:menacwy) { CachedProgramme.menacwy }
    let(:td_ipv) { CachedProgramme.td_ipv }

    context "with only HPV" do
      let(:programmes) { [hpv] }

      it { should eq({ hpv: [hpv] }) }
    end

    context "with Td/IPV and MenACWY" do
      let(:programmes) { [menacwy, td_ipv] }

      it { should eq({ doubles: [menacwy, td_ipv] }) }
    end

    context "with HPV, Td/IPV and MenACWY" do
      let(:programmes) { [hpv, menacwy, td_ipv] }

      it { should eq({ hpv: [hpv], doubles: [menacwy, td_ipv] }) }
    end
  end
end
