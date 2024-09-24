# frozen_string_literal: true

class Sessions::EditController < ApplicationController
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  before_action :set_session
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :set_locations,
                only: %i[show update],
                if: -> { current_step == :location }
  before_action :set_patients,
                only: %i[show update],
                if: -> { current_step == :cohort }
  before_action :validate_params, only: %i[update]

  def show
    render_wizard
  end

  def update
    case current_step
    when :confirm
      @session.active = true
      @session.patient_sessions.update_all(active: true)

      if @session.send_consent_requests_at.today?
        ConsentRequestsSessionBatchJob.perform_later(@session)
      end
    when :cohort
      ActiveRecord::Base.transaction do
        @session.assign_attributes(
          patient_ids: update_params[:patient_ids] || [],
          wizard_step: current_step
        )
        @session.patient_sessions.update_all(
          created_by_user_id: current_user.id
        )
      end
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
    @session =
      policy_scope(Session).where(
        active: params[:id] == Wicked::FINISH_STEP
      ).find(params[:session_id])
  end

  def update_params
    permitted_attributes = {
      location: [:location_id],
      when: %i[date(3i) date(2i) date(1i) time_of_day],
      cohort: {
        all_patients: nil,
        patient_ids: []
      },
      timeline: %i[
        send_consent_requests_at(3i)
        send_consent_requests_at(2i)
        send_consent_requests_at(1i)
        reminder_days_after
        reminder_days_after_custom
        close_consent_on
        close_consent_at
      ]
    }.fetch(current_step)

    params
      .fetch(:session, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def set_steps
    self.steps = @session.wizard_steps
    @previous_step = previous_step
  end

  def set_locations
    # TODO: Don't use limit.
    @locations =
      policy_scope(Location)
        .order(:name)
        .limit(100)
        .map { OpenStruct.new(name: _1.name, value: _1.id) }
  end

  def set_patients
    # Get a list of patients but ensure we don't include patients that are
    # already in other sessions, if those sessions are active (not draft) and
    # for the same vaccine/programme.
    @patients =
      @session
        .location
        .patients
        .where.not(
          Session
            .joins(:patient_sessions)
            .active
            .where(team: @session.team)
            .where("patient_sessions.patient_id = patients.id")
            .arel
            .exists
        )
        .sort_by(&:last_name)
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
        @session.time_of_day = update_params[:time_of_day]
        render_wizard nil, status: :unprocessable_entity
      end
    when :timeline
      validator =
        DateParamsValidator.new(
          field_name: :send_consent_requests_at,
          object: @session,
          params: update_params
        )

      unless validator.date_params_valid?
        @session.send_consent_requests_at = validator.date_params_as_struct
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end
end
