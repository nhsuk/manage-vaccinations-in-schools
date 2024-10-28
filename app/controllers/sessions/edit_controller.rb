# frozen_string_literal: true

class Sessions::EditController < ApplicationController
  before_action :set_session

  def edit_send_consent_requests_at
    render :send_consent_requests_at
  end

  def update_send_consent_requests_at
    if !send_consent_requests_at_validator.date_params_valid?
      @session.send_consent_requests_at =
        send_consent_requests_at_validator.date_params_as_struct
      render :send_consent_requests_at, status: :unprocessable_entity
    elsif !@session.update(send_consent_requests_at_params)
      render :send_consent_requests_at, status: :unprocessable_entity
    else
      redirect_to edit_session_path(@session)
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:slug])
  end

  def send_consent_requests_at_validator
    @send_consent_requests_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_consent_requests_at,
        object: @session,
        params: send_consent_requests_at_params
      )
  end

  def send_consent_requests_at_params
    params.require(:session).permit(:send_consent_requests_at)
  end
end
