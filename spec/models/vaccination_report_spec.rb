# frozen_string_literal: true

describe VaccinationReport do
  describe "file_formats" do
    subject { described_class.file_formats(programme) }

    context "when programme is hpv" do
      let(:programme) { create(:programme, :hpv) }

      it { should eq(%w[careplus mavis systm_one]) }
    end

    context "when programme is menacwy" do
      let(:programme) { create(:programme, :menacwy) }

      it { should eq(%w[careplus mavis]) }
    end

    context "when programme is flu" do
      let(:programme) { create(:programme, :flu) }

      it { should eq(%w[careplus mavis systm_one]) }
    end
  end
end
