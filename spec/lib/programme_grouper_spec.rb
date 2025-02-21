# frozen_string_literal: true

describe ProgrammeGrouper do
  describe "#call" do
    subject(:call) { described_class.call(programmes) }

    let(:hpv) { create(:programme, :hpv) }
    let(:menacwy) { create(:programme, :menacwy) }
    let(:td_ipv) { create(:programme, :td_ipv) }

    context "with only HPV" do
      let(:programmes) { [hpv] }

      it { should eq([[hpv]]) }
    end

    context "with Td/IPV and MenACWY" do
      let(:programmes) { [menacwy, td_ipv] }

      it { should eq([[menacwy, td_ipv]]) }
    end

    context "with HPV, Td/IPV and MenACWY" do
      let(:programmes) { [hpv, menacwy, td_ipv] }

      it { should eq([[hpv], [menacwy, td_ipv]]) }
    end
  end
end
