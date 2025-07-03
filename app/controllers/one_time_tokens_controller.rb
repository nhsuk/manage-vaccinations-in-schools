# frozen_string_literal: true

class OneTimeTokensController < ApplicationController
  include AuthenticationConcern

  skip_before_action :authenticate_user!
  before_action :authenticate_by_token!

  def verify
    skip_policy_scope
    @token = OneTimeToken.find_by!(token: params[:token])
    @token.delete # <- Tokens are one-time use
    render json: @token.attributes.merge(user: @token.user)
  end
end