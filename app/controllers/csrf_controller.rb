class CSRFController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    render json: { token: form_authenticity_token }
  end
end
