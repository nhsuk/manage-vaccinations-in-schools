# frozen_string_literal: true

class JWKSController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  skip_before_action :store_user_location!
  skip_before_action :authenticate_basic

  ## Include extra JWK here. Use:
  # EXTRA_JWK = [{ alg: "RS256", key: <<~EOF }].freeze
  #       -----BEGIN PUBLIC KEY-----
  #       MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs/sFLsdztNW7LBriN++8
  #       IN6IoWaJLAPkn2FfXMV4tWrGs1TKoIAySoodwJIaU27DHnez8v55IwYSRMOa+4fM
  #       oo1xyc6LmeVZLUO8jcuZpM2RsnA9GGLTkwA5XftskOAOrl57JkT46sfkzQs70fPv
  #       70wHyP5x2/dVbTJ7XM/n/5jCZ96yeGP3o8uTDa5DOSTjzWuy7YdOOcSu4AL4RWsx
  #       BCplWaajuOtpZu9Ca66T+Fbo4ihZrOsldHOgAF01wiBLe1ADXvrfDqVAHXxF6WDk
  #       22nUY4sElO0cIpTLXMuDrNiaRp/+HkHrMgwzIwBxefMgTfLlmkhQW0FYNm8b+3ja
  #       wwIDAQAB
  #       -----END PUBLIC KEY-----
  #     EOF
  EXTRA_JWK = [].freeze

  def jwks
    jwk = []

    if Settings.nhs_api&.jwt_private_key.present?
      nhs_api_key = OpenSSL::PKey::RSA.new(Settings.nhs_api.jwt_private_key)
      jwk << key_to_jwk(key: nhs_api_key.public_key, alg: "RS512")
    end

    if Settings.cis2&.private_key.present?
      cis2_key = OpenSSL::PKey::RSA.new(Settings.cis2.private_key)
      jwk << key_to_jwk(key: cis2_key.public_key, alg: "RS256")
    end

    jwk += EXTRA_JWK.map { key_to_jwk(**_1) }

    jwks = JWT::JWK::Set.new(jwk.uniq)
    render json: jwks.export
  end

  private

  def key_to_jwk(key:, alg:)
    key = OpenSSL::PKey::RSA.new(key) if key.is_a?(String)

    JWT::JWK.new(key, { alg: }, kid_generator: ::JWT::JWK::Thumbprint)
  end
end
