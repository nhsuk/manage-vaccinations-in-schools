# frozen_string_literal: true

class DraftGillickAssessmentsController < ApplicationController
  include Wicked::Wizard::Translated

  before_action :set_draft_gillick_assessment
  before_action :set_patient_session
  before_action :set_patient
  before_action :set_session
  before_action :set_gillick_assessment
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :set_locations

  after_action :verify_authorized

  # This is handled by DraftGillickAssessment.
  skip_after_action :verify_policy_scoped

  def show
    authorize GillickAssessment, :edit?

    render_wizard
  end

  def update
    authorize GillickAssessment

    @draft_gillick_assessment.assign_attributes(update_params)

    handle_confirm if current_step == :confirm

    render_wizard @draft_gillick_assessment
  end

  private

  def handle_confirm
    return unless @draft_gillick_assessment.save

    @draft_gillick_assessment.write_to!(@gillick_assessment)
    @gillick_assessment.save!
  end

  def finish_wizard_path
    session_patient_path(
      @session,
      @patient,
      section: "consents",
      tab: "no-consent"
    )
  end

  def set_draft_gillick_assessment
    @draft_gillick_assessment =
      DraftGillickAssessment.new(request_session: session, current_user:)
  end

  def set_patient_session
    @patient_session = @draft_gillick_assessment.patient_session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_session
    @session = @patient_session.session
  end

  def set_gillick_assessment
    @gillick_assessment =
      @draft_gillick_assessment.gillick_assessment ||
        GillickAssessment.new(recorded_at: Time.current)
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @draft_gillick_assessment.wizard_steps
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic if current_step ==
      :location
  end

  def update_params
    params
      .fetch(:draft_gillick_assessment, {})
      .permit(:gillick_competent, :location_name, :notes)
      .merge(wizard_step: current_step)
  end

  def current_step
    @current_step ||= wizard_value(step)&.to_sym
  end
end
