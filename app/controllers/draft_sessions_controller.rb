# frozen_string_literal: true

class DraftSessionsController < ApplicationController
  before_action :set_draft_session
  before_action :set_session

  include WizardControllerConcern

  before_action :validate_params, only: :update
  before_action :set_back_link_path

  skip_after_action :verify_policy_scoped

  def show
    authorize @session, :edit?

    render_wizard
  end

  def update
    authorize @session, :update?

    if current_step == :confirm
      handle_confirm
    else
      @draft_session.assign_attributes(update_params)
    end

    jump_to("confirm") if @draft_session.editing? && current_step != :confirm

    render_wizard @draft_session
  end

  private

  def set_draft_session
    @draft_session = DraftSession.new(request_session: session, current_user:)
  end

  def set_session
    @session = @draft_session.session
  end

  def set_steps
    self.steps = @draft_session.wizard_steps
  end

  def validate_params
    if current_step == :consent_requests
      unless send_consent_requests_at_validator.date_params_valid?
        @draft_session.errors.add(:send_consent_requests_at_validator, :invalid)
        render_wizard nil, status: :unprocessable_content
      end
    elsif current_step == :invitations
      unless send_invitations_at_validator.date_params_valid?
        @draft_session.errors.add(:send_consent_requests_at_validator, :invalid)
        render_wizard nil, status: :unprocessable_content
      end
    end
  end

  def set_back_link_path
    @back_link_path =
      if current_step == :confirm
        session_path(@session)
      else
        wizard_path("confirm")
      end
  end

  def handle_confirm
    return unless @draft_session.save

    @draft_session.write_to!(@session)

    ActiveRecord::Base.transaction do
      @session.save!
      @draft_session.create_location_programme_year_groups!
    end

    StatusUpdaterJob.perform_later(session: @session)
  end

  def finish_wizard_path = session_path(@session)

  def update_params
    permitted_attributes = {
      consent_reminders: %i[weeks_before_consent_reminders],
      consent_requests: %i[send_consent_requests_at],
      delegation: %i[psd_enabled national_protocol_enabled],
      invitations: %i[send_invitations_at],
      programmes: %i[programme_ids],
      register_attendance: %i[requires_registration]
    }.fetch(current_step)

    params
      .fetch(:draft_session, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def send_consent_requests_at_validator
    @send_consent_requests_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_consent_requests_at,
        object: @draft_session,
        params: update_params
      )
  end

  def send_invitations_at_validator
    @send_invitations_at_validator ||=
      DateParamsValidator.new(
        field_name: :send_invitations_at,
        object: @draft_session,
        params: update_params
      )
  end
end
