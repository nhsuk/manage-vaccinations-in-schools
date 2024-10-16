# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: %i[start jwks]
  skip_before_action :store_user_location!, only: :start

  def start
  end

  def jwks
    public_pem = <<~PEM
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs/sFLsdztNW7LBriN++8
      IN6IoWaJLAPkn2FfXMV4tWrGs1TKoIAySoodwJIaU27DHnez8v55IwYSRMOa+4fM
      oo1xyc6LmeVZLUO8jcuZpM2RsnA9GGLTkwA5XftskOAOrl57JkT46sfkzQs70fPv
      70wHyP5x2/dVbTJ7XM/n/5jCZ96yeGP3o8uTDa5DOSTjzWuy7YdOOcSu4AL4RWsx
      BCplWaajuOtpZu9Ca66T+Fbo4ihZrOsldHOgAF01wiBLe1ADXvrfDqVAHXxF6WDk
      22nUY4sElO0cIpTLXMuDrNiaRp/+HkHrMgwzIwBxefMgTfLlmkhQW0FYNm8b+3ja
      wwIDAQAB
      -----END PUBLIC KEY-----
    PEM
    public_key = OpenSSL::PKey::RSA.new(public_pem)
    jwk = JWT::JWK.new(public_key)
    jwks = JWT::JWK::Set.new([jwk])
    render json: jwks.export
  end
end
