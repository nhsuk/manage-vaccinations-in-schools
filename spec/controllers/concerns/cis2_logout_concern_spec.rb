# frozen_string_literal: true

describe CIS2LogoutConcern do
  let(:klass) do
    Class.new do
      include CIS2LogoutConcern
      attr_accessor :params

      def initialize(params)
        @params = params
      end

      def logout
        perform_logout(params[:logout_token])
      end
    end
  end
  let(:params) { { logout_token: "1234567890" } }

  describe "validate_logout_token" do
    subject { klass.new(params).send(:validate_logout_token, "token") }

    before do
      create(:user, :signed_in, uid: "user123", current_sign_in_at:)
      allow(JWT).to receive(:decode).and_return([payload, header])
    end

    let(:current_sign_in_at) { Time.zone.now }
    let(:header) { { "alg" => "RS256" } }
    let(:iss) { "https://localhost:4000/oidc/realms/test" }
    let(:aud) { "31337.apps.national" }
    let(:iat) { Time.zone.now.to_i }
    let(:sub) { "user123" }
    let(:exp) { 1.hour.from_now.to_i }
    let(:events) do
      { "http://schemas.openid.net/event/backchannel-logout" => {} }
    end
    let(:payload) { { events:, iss:, aud:, iat:, exp:, sub: }.stringify_keys }

    it { should be true }

    context "when alg is unknown" do
      let(:header) { { "alg" => "HS256" } }

      it { should be false }
    end

    context "when token does not match issuer" do
      let(:iss) { "https://example.com" }

      it { should be false }
    end

    context "when token does not match client id (aud)" do
      let(:aud) { "BADclient" }

      it { should be false }
    end

    context "when token is too old" do
      let(:iat) { 301.seconds.ago }

      it { should be false }
    end

    context "when issued_at (iat) is in the future" do
      let(:iat) { 10.seconds.from_now.to_i }

      it { should be false }
    end

    context "when sub claim does not match user uid" do
      let(:sub) { "invalid_user" }

      it { should be false }
    end

    context "when signature is invalid" do
      before do
        allow(JWT).to receive(:decode).and_raise(JWT::VerificationError)
      end

      it { should be false }
    end

    context "when user is not found" do
      let(:sub) { "non_existent_user" }

      it { should be false }
    end

    context "when token is expired" do
      let(:exp) { 1.hour.ago.to_i }

      it { should be false }
    end

    context "when token is missing backchannel event" do
      let(:events) { {} }

      it { should be false }
    end
  end
end
