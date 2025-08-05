# frozen_string_literal: true

class Sessions::EditController < ApplicationController
  before_action :set_session

  def edit_programmes
    @form =
      SessionProgrammesForm.new(
        session: @session,
        programme_ids: @session.programme_ids
      )

    render :programmes
  end

  def update_programmes
    @form = SessionProgrammesForm.new(session: @session, **programmes_params)

    if @form.save
      redirect_to edit_session_path(@session)
    else
      render :programmes, status: :unprocessable_content
    end
  end

  def edit_send_consent_requests_at
    render :send_consent_requests_at
  end

  def update_send_consent_requests_at
    if !send_consent_requests_at_validator.date_params_valid?
      @session.send_consent_requests_at =
        send_consent_requests_at_validator.date_params_as_struct
      render :send_consent_requests_at, status: :unprocessable_content
    elsif !@session.update(send_consent_requests_at_params)
      render :send_consent_requests_at, status: :unprocessable_content
    else
      redirect_to edit_session_path(@session)
    end
  end

  def edit_send_invitations_at
    render :send_invitations_at
  end

  def update_send_invitations_at
    if !send_invitations_at_validator.date_params_valid?
      @session.send_invitations_at =
        send_invitations_at_validator.date_params_as_struct
      render :send_invitations_at, status: :unprocessable_content
    elsif !@session.update(send_invitations_at_params)
      render :send_invitations_at, status: :unprocessable_content
    else
      redirect_to edit_session_path(@session)
    end
  end

  def edit_weeks_before_consent_reminders
    render :weeks_before_consent_reminders
  end

  def update_weeks_before_consent_reminders
    if @session.update(weeks_before_consent_reminders_params)
      redirect_to edit_session_path(@session)
    else
      render :weeks_before_consent_reminders, status: :unprocessable_content
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:slug])
  end

  def programmes_params
    params.expect(session_programmes_form: { programme_ids: [] })
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
    params.expect(session: :send_consent_requests_at)
  end

  def send_invitations_at_validator
    @send_invitations_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_invitations_at,
        object: @session,
        params: send_invitations_at_params
      )
  end

  def send_invitations_at_params
    params.expect(session: :send_invitations_at)
  end

  def weeks_before_consent_reminders_params
    params.expect(session: :weeks_before_consent_reminders)
  end
end
