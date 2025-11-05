# frozen_string_literal: true

describe VaccinesHelper do
  let(:vaccine) { Vaccine.find_by!(brand: "Fluenz") }

  describe "#vaccine_heading" do
    subject { helper.vaccine_heading(vaccine) }

    it { should eq("Fluenz (Flu)") }
  end
end
