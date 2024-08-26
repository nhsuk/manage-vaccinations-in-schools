# frozen_string_literal: true

describe NHS::API do
  before do
    allow(JWT).to receive(:encode).and_return("jwt")
    allow(OpenSSL::PKey::RSA).to receive(:new).and_return("key")
  end

  describe ".connection_sans_auth" do
    it "sets the url" do
      expect(
        described_class.connection_sans_auth.url_prefix.to_s
      ).to eq "https://sandbox.api.service.nhs.uk/"
    end

    describe "headers" do
      subject { described_class.connection_sans_auth.headers }

      before do
        allow(SecureRandom).to receive(:uuid).and_return("UUIDMCUUIDFACE")
      end

      it { should include(accept: "application/fhir+json") }
      it { should include(x_request_id: "UUIDMCUUIDFACE") }
    end
  end

  describe ".connection" do
    it "sets the authorization header" do
      allow(described_class).to receive(:access_token).and_return("ONEAUTHAPI")
      expect(described_class.connection.headers).to include(
        authorization: "Bearer ONEAUTHAPI"
      )
    end
  end

  describe ".access_token" do
    before do
      stub_request(
        :post,
        "https://sandbox.api.service.nhs.uk/oauth2/token"
      ).to_return(
        status: 200,
        body: {
          issued_at: Time.zone.now.strftime("%Q"),
          expires_in: 599,
          access_token: "new_token"
        }.to_json
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

  describe ".access_token_valid?" do
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
