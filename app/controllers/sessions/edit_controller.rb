# frozen_string_literal: true

class Sessions::EditController < ApplicationController
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  before_action :set_session
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :validate_params, only: %i[update]

  def show
    render_wizard
  end

  def update
    @session.assign_attributes update_params
    render_wizard @session
  end

  private

  def finish_wizard_path
    edit_session_path(@session)
  end

  def set_session
    @session = policy_scope(Session).find(params[:session_id])
  end

  def update_params
    params
      .fetch(:session, {})
      .permit(%i[date(3i) date(2i) date(1i)])
      .merge(wizard_step: wizard_value(step)&.to_sym)
  end

  def set_steps
    self.steps = @session.wizard_steps
    @previous_step = previous_step
  end

  def validate_params
    validator =
      DateParamsValidator.new(
        field_name: :date,
        object: @session,
        params: update_params
      )

    unless validator.date_params_valid?
      @session.date = validator.date_params_as_struct
      render_wizard nil, status: :unprocessable_entity
    end
  end
end
