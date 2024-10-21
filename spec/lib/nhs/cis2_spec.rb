# frozen_string_literal: true

describe NHS::CIS2 do
  describe "jwks_fetcher" do
    subject { described_class.send(:jwks_fetcher).call({}) }

    let(:jwks_uri) { "http://localhost:4000/jwks" }
    let(:jwks_response) { { keys: [{ kid: "key1", use: "sig" }] }.to_json }

    before do
      allow(described_class).to receive(:jwks_uri).and_return(jwks_uri)
      stub_request(:get, jwks_uri).to_return(status: 200, body: jwks_response)
    end

    context "when jwks is cached" do
      before do
        allow(Rails.cache).to receive(:fetch).with("cis2:jwks").and_return(
          "cached jwks"
        )
      end

      it { should be "cached jwks" }
      it { should_not have_requested(:get, jwks_uri) }
    end

    context "when no jwks is cached" do
      before do
        allow(Rails.cache).to receive(:fetch).with(
          "cis2:jwks"
        ).and_call_original
      end

      it "fetches the jwks" do
        allow(JWT::JWK::Set).to receive(:new).and_return(
          [{ kid: "key1", use: "sig" }, kid: "key2", use: "enc"]
        )

        expect(subject).to eq [{ kid: "key1", use: "sig" }]
      end
    end
  end

  describe "openid_configuration" do
    subject { described_class.send(:openid_configuration) }

    let(:config_uri) do
      "https://localhost:4000/oidc/realms/test/.well-known/openid-configuration"
    end
    let(:config_response) { { jwks_uri: "https://example.com/jwks" }.to_json }

    before do
      stub_request(:get, config_uri).to_return(
        status: 200,
        body: config_response
      )

      described_class.instance_variable_set(:@openid_configuration, nil)
    end

    after { Rails.cache.delete("cis2:openid_configuration") }

    it { should eq JSON.parse(config_response) }

    it "caches the response" do
      allow(Rails.cache).to receive(:fetch).with(
        "cis2:openid_configuration",
        expires_in: 1.day
      ).and_call_original

      subject

      expect(Rails.cache).to have_received(:fetch)
    end

    context "when openid_configurations is not cached" do
      it { should have_requested(:get, config_uri) }
    end
  end
end
