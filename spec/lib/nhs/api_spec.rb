# frozen_string_literal: true

describe NHS::API do
  before do
    allow(JWT).to receive(:encode).and_return("jwt")
    allow(OpenSSL::PKey::RSA).to receive(:new).and_return("key")
  end

  describe "#connection" do
    subject(:connection) { described_class.connection }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("UUIDMCUUIDFACE")
      Settings.nhs_api.apikey = "key"
    end

    after { Settings.reload! }

    context "when authentication is disabled" do
      before { Settings.nhs_api.disable_authentication = true }

      describe "url_prefix" do
        subject(:url) { connection.url_prefix.to_s }

        it { should eq("https://sandbox.api.service.nhs.uk/") }
      end

      describe "headers" do
        subject(:headers) { connection.headers }

        it { should include(accept: "application/fhir+json") }
        it { should include(apikey: "key") }
        it { should_not have_key(:authorization) }
        it { should include(x_request_id: "UUIDMCUUIDFACE") }
      end
    end

    context "when authentication is enabled" do
      before do
        Settings.nhs_api.disable_authentication = false

        allow(described_class).to receive(:access_token).and_return(
          "ONEAUTHAPI"
        )
      end

      describe "url_prefix" do
        subject(:url) { connection.url_prefix.to_s }

        it { should eq("https://sandbox.api.service.nhs.uk/") }
      end

      describe "headers" do
        subject(:headers) { connection.headers }

        it { should include(accept: "application/fhir+json") }
        it { should include(apikey: "key") }
        it { should include(authorization: "Bearer ONEAUTHAPI") }
        it { should include(x_request_id: "UUIDMCUUIDFACE") }
      end
    end
  end

  describe "#access_token" do
    before do
      stub_request(
        :post,
        "https://sandbox.api.service.nhs.uk/oauth2/token"
      ).to_return_json(
        body: {
          issued_at: Time.zone.now.strftime("%Q"),
          expires_in: 599,
          access_token: "new_token"
        }
      )
    end

    it "fetches a new auth token when we don't have one" do
      allow(described_class).to receive(:access_token_valid?).and_return(false)

      expect(described_class.access_token).to eq("new_token")
    end

    it "does not fetch a new token when we already have one" do
      allow(described_class).to receive(:access_token_valid?).and_return(
        false,
        true
      )

      described_class.access_token
      described_class.access_token

      expect(
        a_request(:post, "https://sandbox.api.service.nhs.uk/oauth2/token")
      ).to have_been_made.once
    end
  end

  describe "#access_token_valid?" do
    it "returns false when we have no auth_info" do
      described_class.instance_variable_set(:@auth_info, nil)

      expect(described_class.access_token_valid?).to be false
    end

    it "returns true if our auth_info is still valid" do
      described_class.instance_variable_set(
        :@auth_info,
        { expires_at: (Time.zone.now.strftime("%Q").to_i + 600_000) }
      )

      expect(described_class.access_token_valid?).to be true
    end

    it "returns false if the auth_info has expired" do
      described_class.instance_variable_set(
        :@auth_info,
        { expires_at: (Time.zone.now.strftime("%Q").to_i - 600_000) }
      )
      expect(described_class.access_token_valid?).to be false
    end
  end
end
