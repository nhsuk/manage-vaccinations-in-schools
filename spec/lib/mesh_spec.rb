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
      described_class.send_file(to: "TESTBOX", data: "some,csv")

      expect(
        a_request(
          :post,
          "https://localhost:8700/messageexchange/X26ABC1/outbox"
        ).with(
          headers: {
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Content-Type" => "text/csv",
            "Content-Encoding" => "gzip",
            "Mex-To" => "TESTBOX",
            "Mex-Workflowid" => "dps export",
            "User-Agent" => "Faraday v2.10.0"
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

  describe "#connection" do
    it "disables ssl in development" do
      allow(Rails).to receive(:env).and_return(
        instance_double(ActiveSupport::EnvironmentInquirer, development?: true)
      )

      expect(described_class.connection.ssl).to have_attributes(verify: false)
    end

    it "enables ssl in production" do
      allow(Rails).to receive(:env).and_return(
        instance_double(ActiveSupport::EnvironmentInquirer, development?: false)
      )

      expect(described_class.connection.ssl).to have_attributes(verify: true)
    end

    it "sets the url" do
      expect(
        described_class.connection.url_prefix.to_s
      ).to eq "https://localhost:8700/messageexchange/X26ABC1/"
    end

    it "sets the authorisation header" do
      allow(described_class).to receive(:generate_authorisation).and_return(
        "AUTHORIZATIONSTRING"
      )

      expect(
        described_class.connection.headers["Authorization"]
      ).to eq "NHSMESH AUTHORIZATIONSTRING"
    end

    it "sets the accept header" do
      expect(
        described_class.connection.headers["Accept"]
      ).to eq "application/vnd.mesh.v2+json"
    end
  end
end
