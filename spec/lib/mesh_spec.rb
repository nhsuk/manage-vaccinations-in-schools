# frozen_string_literal: true

require "rails_helper"

describe MESH do
  before do
    stub_request(
      :post,
      "https://localhost:8700/messageexchange/X26ABC1/outbox"
    ).to_return(status: 200, body: "", headers: {})

    stub_request(
      :get,
      "https://localhost:8700/messageexchange/X26ABC1"
    ).to_return(status: 200, body: "", headers: {})

    allow(Etc).to receive(:uname).and_return(
      {
        sysname: "mex-osname test",
        release: "mex-osversion test",
        machine: "mex-osarchitecture test"
      }
    )
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
            "Content-Type" => "application/octet-stream",
            "Content-Encoding" => "gzip",
            "Mex-To" => "TESTBOX",
            "Mex-Workflowid" => "dps export",
            "User-Agent" => /Faraday v.+/,
            "Mex-Clientversion" => "Mavis 1.0.0",
            "Mex-Osarchitecture" => "mex-osarchitecture test",
            "Mex-Osname" => "mex-osname test",
            "Mex-Osversion" => "mex-osversion test"
          }
        )
      ).to have_been_made
    end
  end

  describe "#validate_mailbox" do
    it "makes a request to the correct endpoint" do
      described_class.validate_mailbox

      expect(
        a_request(:get, "https://localhost:8700/messageexchange/X26ABC1").with(
          headers: {
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => /Faraday v.+/,
            "Mex-Clientversion" => "Mavis 1.0.0",
            "Mex-Osarchitecture" => "mex-osarchitecture test",
            "Mex-Osname" => "mex-osname test",
            "Mex-Osversion" => "mex-osversion test"
          }
        )
      ).to have_been_made
    end
  end

  describe "#track_message" do
    let(:response_body) do
      JSON.generate(
        {
          message_id: "MESSAGEID",
          local_id: "",
          workflow_id: "dps export",
          filename: "MESSAGEID.dat",
          expiry_time: "2024-08-28T13:59:32.079731",
          upload_timestamp: "2024-08-23T13:59:32.079939",
          recipient: "X26ABC3",
          recipient_name: "TESTMB3",
          recipient_ods_code: "X27",
          recipient_org_code: "X27",
          recipient_org_name: "",
          status_success: true,
          status: "accepted"
        }
      )
    end

    before do
      stub_request(
        :get,
        "https://localhost:8700/messageexchange/X26ABC1/outbox/tracking?messageID=MESSAGEID"
      ).to_return(status: 200, body: response_body, headers: {})
    end

    it "makes a request to the correct endpoint" do
      described_class.track_message("MESSAGEID")

      expect(
        a_request(
          :get,
          "https://localhost:8700/messageexchange/X26ABC1/outbox/tracking"
        ).with(
          query: {
            "messageID" => "MESSAGEID"
          },
          headers: {
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => /Faraday v.+/,
            "Mex-Clientversion" => "Mavis 1.0.0",
            "Mex-Osarchitecture" => "mex-osarchitecture test",
            "Mex-Osname" => "mex-osname test",
            "Mex-Osversion" => "mex-osversion test"
          }
        )
      ).to have_been_made
    end

    it "returns the response" do
      response = described_class.track_message("MESSAGEID")
      expect(response.body).to eq(response_body)
      expect(response.status).to eq(200)
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
    it "uses ssl_options" do
      allow(described_class).to receive(:ssl_options).and_return(verify: true)
      expect(described_class.connection.ssl).to have_attributes(verify: true)
    end

    it "sets the url" do
      expect(
        described_class.connection.url_prefix.to_s
      ).to eq "https://localhost:8700/messageexchange/X26ABC1"
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

  describe "#ssl_options" do
    it "loads ssl settings when not configured to disabled verification" do
      allow(OpenSSL::X509::Certificate).to receive(:new).and_return(
        "CERTIFICATE"
      )
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return("PRIVATEKEY")
      # rubocop:disable RSpec/VerifiedDoubles
      allow(Settings).to receive(:mesh).and_return(
        double(
          disable_ssl_verification: nil,
          certificate: "CERTIFICATE64",
          private_key: "PRIVATEKEY64",
          private_key_passphrase: "PASSPHRASE"
        )
      )
      # rubocop:enable RSpec/VerifiedDoubles

      expect(described_class.ssl_options).to include(
        verify: true,
        client_cert: "CERTIFICATE",
        client_key: "PRIVATEKEY"
      )
    end

    it "disables ssl in dev mode" do
      # rubocop:disable RSpec/VerifiedDoubles
      allow(Settings).to receive(:mesh).and_return(
        double(disable_ssl_verification: true)
      )
      # rubocop:enable RSpec/VerifiedDoubles

      expect(described_class.ssl_options).to include(verify: false)
    end
  end
end
