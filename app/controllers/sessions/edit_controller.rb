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
    case current_step
    when :confirm
      @session.patient_sessions.update_all(active: true)
    else
      @session.assign_attributes update_params
    end

    render_wizard @session
  end

  private

  def current_step
    wizard_value(step)&.to_sym
  end

  def finish_wizard_path
    session_path(@session)
  end

  def set_session
    @session = policy_scope(Session).find(params[:session_id])
  end

  def update_params
    permitted_attributes = { when: %i[date(3i) date(2i) date(1i)] }.fetch(
      current_step
    )

    params
      .fetch(:session, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def set_steps
    self.steps = @session.wizard_steps
    @previous_step = previous_step
  end

  def validate_params
    case current_step
    when :when
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
end
