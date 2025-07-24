# frozen_string_literal: true

describe VaccinesHelper do
  let(:vaccine) { create(:vaccine, :fluenz) }

  describe "#vaccine_heading" do
    subject { helper.vaccine_heading(vaccine) }

    it { should eq("Fluenz (Flu)") }
  end
end
