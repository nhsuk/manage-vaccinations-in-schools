# frozen_string_literal: true

require "rails_helper"

RSpec.describe VaccinesHelper, type: :helper do
  let(:vaccine) { create(:vaccine, :flu) }

  describe "#vaccine_heading" do
    subject(:vaccine_heading) { helper.vaccine_heading(vaccine) }

    it { should eq("Fluenz Tetra (Flu)") }
  end

  describe "#vaccine_dose" do
    subject(:vaccine_dose) { helper.vaccine_dose(vaccine) }

    it { should eq("0.2 ml") }
  end
end
