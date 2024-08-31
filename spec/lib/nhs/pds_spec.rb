# frozen_string_literal: true

describe NHS::PDS do
  before { allow(NHS::API).to receive(:connection).and_return(Faraday.new) }

  describe ".connection" do
    it "sets the url" do
      expect(
        described_class.connection.url_prefix.to_s
      ).to eq "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4"
    end
  end
end
