class CSRFController < ApplicationController
  def new
    render json: { token: form_authenticity_token }
  end
end
