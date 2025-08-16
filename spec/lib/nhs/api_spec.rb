# frozen_string_literal: true

describe NHS::API do
  before { described_class.instance_variable_set(:@auth_info, nil) }

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
        it { should include(apikey: "test_key") }
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
        it { should include(apikey: "test_key") }
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
          access_token: "new-token"
        }
      )
    end

    it "fetches a new auth token when we don't have one" do
      allow(described_class).to receive(:access_token_expired?).and_return(true)

      expect(described_class.access_token).to eq("new-token")
    end

    it "does not fetch a new token when we already have one" do
      allow(described_class).to receive(:access_token_expired?).and_return(
        true,
        false
      )

      described_class.access_token
      described_class.access_token

      expect(
        a_request(:post, "https://sandbox.api.service.nhs.uk/oauth2/token")
      ).to have_been_made.once
    end

    describe "JWT headers in the request" do
      before { described_class.access_token }

      ## How to generate the kid from our test private key:
      # private_key = OpenSSL::PKey::RSA.new(Settings.nhs_api.jwt_private_key)
      # jwk = JWT::JWK.new(private_key, kid_generator: ::JWT::JWK::Thumbprint))
      # jwk.kid
      let(:kid) { "8nMGS9Os9P6iDOURi3kHqkhAO7d1rwgoFyMnROITzCM" }

      def jwt_headers(req)
        params = Rack::Utils.parse_nested_query(req.body)
        client_assertion = params["client_assertion"]
        JSON.parse(Base64.decode64(client_assertion.split(".").first))
      end

      it "has alg set" do
        expect(
          a_request(
            :post,
            "https://sandbox.api.service.nhs.uk/oauth2/token"
          ).with { |req| jwt_headers(req)["alg"] == "RS512" }
        ).to have_been_made
      end

      it "has typ set" do
        expect(
          a_request(
            :post,
            "https://sandbox.api.service.nhs.uk/oauth2/token"
          ).with { |req| jwt_headers(req)["typ"] == "JWT" }
        ).to have_been_made
      end

      it "has kid set" do
        expect(
          a_request(
            :post,
            "https://sandbox.api.service.nhs.uk/oauth2/token"
          ).with { |req| jwt_headers(req)["kid"] == kid }
        ).to have_been_made
      end
    end
  end

  describe "#access_token_expired?" do
    subject(:access_token_expired?) { described_class.access_token_expired? }

    before { described_class.instance_variable_set(:@auth_info, auth_info) }

    context "with no auth_info" do
      let(:auth_info) { nil }

      it { should be(true) }
    end

    context "when auth_info is still valid" do
      let(:auth_info) { { expires_at: 1.minute.from_now } }

      it { should be(false) }
    end

    context "when auth_info has expired" do
      let(:auth_info) { { expires_at: 1.minute.ago } }

      it { should be(true) }
    end
  end
end
