# frozen_string_literal: true

class CSRFController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def new
    render json: { token: form_authenticity_token }
  end
end
