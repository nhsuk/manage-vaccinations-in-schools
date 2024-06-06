class ManageConsentsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked
  include TriageMailerConcern

  layout "two_thirds"

  before_action :set_route
  before_action :set_session
  before_action :set_patient
  before_action :set_consent, except: %i[create]
  before_action :set_steps, except: %i[create]
  before_action :setup_wizard_translated, except: %i[create]
  before_action :set_patient_session
  before_action :set_triage,
                except: %i[create],
                if: -> { step.in?(%w[triage confirm]) }
  before_action :set_back_link,
                only: %i[show],
                if: -> { wizard_value(step).present? }

  def create
    @consent = Consent.create! create_params

    set_steps # The form_steps can change after certain attrs change
    setup_wizard_translated # Next/previous steps can change after steps change

    redirect_to action: :show, id: steps.first, consent_id: @consent.id
  end

  def show
    render_wizard
  end

  def update
    case current_step
    when :confirm
      handle_confirm
    when :questions
      handle_questions
    when :triage
      handle_triage
    when :agree
      handle_agree
    else
      @consent.assign_attributes(update_params)
    end

    set_steps # The form_steps can change after certain attrs change
    setup_wizard_translated # Next/previous steps can change after steps change

    render_wizard @consent
  end

  def clone
    existing_consent = policy_scope(Consent).find(params.delete(:consent_id))
    @consent =
      existing_consent.dup.tap do |consent|
        consent.recorded_at = nil
        consent.recorded_by = current_user
      end

    handle_agree
    set_steps
    setup_wizard_translated

    @consent.save!
    redirect_to wizard_path(next_step, consent_id: @consent.id)
  end

  private

  def set_back_link
    current_step # Set the current_step for the back link
  end

  def current_step
    @current_step ||= wizard_value(step).to_sym
  end

  def finish_wizard_path
    flash[:success] = {
      heading: "Consent recorded for",
      heading_link_text: @patient.full_name,
      heading_link_href: session_patient_path(@session, id: @patient.id)
    }

    session_section_path(@session, section: @section)
  end

  def handle_confirm
    ActiveRecord::Base.transaction do
      @consent.recorded_at = Time.zone.now
      @consent.save!

      if @consent.response_refused?
        @triage.update! status: "do_not_vaccinate", user: current_user
      end

      if @triage.persisted?
        @patient_session.do_consent!
        @patient_session.do_triage!
        send_triage_mail(@patient_session, @consent)
      else
        # We need to discard the draft triage record so that the patient
        # session can be saved.
        @triage.destroy!
        @patient_session.do_consent!
      end
    end
  end

  def handle_questions
    questions_attrs = update_params.except(:form_step).values
    @consent.health_answers.each_with_index do |ha, index|
      ha.assign_attributes(questions_attrs[index])
    end

    @consent.assign_attributes(form_step: current_step)
  end

  def handle_triage
    triage_attrs = update_params.delete(:triage).merge(user: current_user)
    @triage.update! triage_attrs

    @consent.assign_attributes(triage: @triage, form_step: current_step)
  end

  def handle_agree
    response_was_given = @consent.response_given?
    @consent.assign_attributes(update_params)

    if !response_was_given && @consent.response_given?
      @consent.health_answers = @session.health_questions.to_health_answers
      @consent.reason_for_refusal = nil
    elsif response_was_given && !@consent.response_given?
      @consent.health_answers = []
      @consent.reason_for_refusal = nil
    end
  end

  def set_route
    @section = params[:section]
  end

  def set_session
    @session = policy_scope(Session).find(params.fetch(:session_id))
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_consent
    @consent =
      policy_scope(Consent).unscope(where: :recorded_at).find(
        params[:consent_id]
      )
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_triage
    @triage = Triage.find_or_initialize_by(patient_session: @patient_session)
  end

  def create_params
    route =
      if @patient_session.gillick_competent?
        :self_consent
      else
        params.permit(:consent)[:consent]
      end

    attrs = { patient: @patient, campaign: @session.campaign, route: }

    no_consent =
      @patient.consents.submitted_for_campaign(@session.campaign).empty?

    # Temporary: Prefill the consent details.
    # This should be replaced with the design that allows users to choose
    # from available parent details when submiting a new consent.
    if route == "phone" && no_consent
      attrs.merge!(
        parent_name: @patient.parent_name,
        parent_phone: @patient.parent_phone,
        parent_email: @patient.parent_email,
        parent_relationship: @patient.parent_relationship,
        recorded_by: current_user
      )
    end

    attrs
  end

  def update_params
    permitted_attributes = {
      assessing_gillick: %i[],
      gillick: %i[],
      who: %i[
        parent_name
        parent_phone
        parent_relationship
        parent_relationship_other
      ],
      agree: %i[response],
      reason: %i[reason_for_refusal],
      reason_notes: %i[reason_for_refusal_notes],
      questions: questions_params,
      triage: {
        triage: %i[notes status]
      }
    }.fetch(current_step)

    params
      .fetch(:consent, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  # Returns:
  # {
  #   question_0: %i[notes response],
  #   question_1: %i[notes response],
  #   question_2: %i[notes response],
  #   ...
  #   triage: %i[notes status]
  # }
  def questions_params
    n = @consent.health_answers.size

    Array.new(n) { |index| ["question_#{index}", %i[notes response]] }.to_h
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @consent.form_steps
  end
end
