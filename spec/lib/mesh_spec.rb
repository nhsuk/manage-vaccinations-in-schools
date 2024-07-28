# frozen_string_literal: true

require "rails_helper"

describe MESH do
  before do
    stub_request(
      :post,
      "https://localhost:8700/messageexchange/X26ABC1/outbox"
    ).to_return(status: 200, body: "", headers: {})
  end

  describe "#send_file" do
    it "sends the data compressed" do
      described_class.send_file(to: "TESTBOX", data: "some,csv")

      expect(
        a_request(
          :post,
          "https://localhost:8700/messageexchange/X26ABC1/outbox"
        ).with(body: Zlib.gzip("some,csv"))
      ).to have_been_made
    end

    it "sets the required headers" do
      allow(described_class).to receive(:generate_authorisation).and_return(
        "AUTHORIZATIONSTRING"
      )

      described_class.send_file(to: "TESTBOX", data: "some,csv")

      expect(
        a_request(
          :post,
          "https://localhost:8700/messageexchange/X26ABC1/outbox"
        ).with(
          headers: {
            "Accept" => "application/vnd.mesh.v2+json",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "NHSMESH AUTHORIZATIONSTRING",
            "Content-Type" => "text/csv",
            "Content-Encoding" => "gzip",
            "Mex-To" => "TESTBOX",
            "Mex-Workflowid" => "dps export",
            "User-Agent" => "Ruby"
          }
        )
      ).to have_been_made
    end
  end

  describe "#generate_authorisation" do
    it "returns the correct string" do
      # Test authorisation header generated with
      # https://nhsdigital.github.io/mesh_validate_auth_header/
      Timecop.freeze(Time.zone.local(2022, 2, 22, 22, 22, 22)) do
        allow(SecureRandom).to receive(:uuid).and_return(
          "deadbeef-dead-beef-dead-beef00031337"
        )
        expect(described_class.generate_authorisation).to eq %w[
             X26ABC1
             deadbeef-dead-beef-dead-beef00031337
             1
             202202222222
             6e27345bec8d29ea1a3c9d87870b0b5bc98ee510921616506bca1bbea7c66fd6
           ].join(":")
      end
    end
  end
end
