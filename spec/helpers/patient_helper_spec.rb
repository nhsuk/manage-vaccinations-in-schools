# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientHelper do
  describe "#format_nhs_number" do
    subject(:formatted_nhs_number) { helper.format_nhs_number(nhs_number) }

    let(:nhs_number) { "0123456789" }

    it "adds spaces in the right place" do
      expect(formatted_nhs_number).to eq("012 345 6789")
    end
  end
end
