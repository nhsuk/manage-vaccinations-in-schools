# frozen_string_literal: true

class Consents::EditController < ApplicationController
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked
  include TriageMailerConcern

  before_action :set_session
  before_action :set_patient
  before_action :set_consent
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :set_parent,
                if: -> { %w[parent-details confirm].include?(step) }
  before_action :set_parent_relationship,
                if: -> { %w[parent-details confirm].include?(step) }
  before_action :set_parent_details_form, if: -> { step == "parent-details" }
  before_action :set_patient_session
  before_action :set_parent_options, if: -> { step == "who" }
  before_action :set_triage, if: -> { step.in?(%w[triage confirm]) }
  before_action :set_back_link,
                only: :show,
                if: -> { wizard_value(step).present? }

  def show
    render_wizard
  end

  def update
    model = @consent

    case current_step
    when :who
      handle_who
    when :confirm
      handle_confirm
    when :parent_details
      model = @parent_details_form
      handle_parent_details

      if model.valid?
        ActiveRecord::Base.transaction do
          if model.save
            @consent.assign_attributes(wizard_step: current_step)
            @consent.save! # in case the @consent.draft_parent was nil previously
          end
        end
      end
    when :questions
      handle_questions
    when :triage
      model = @triage
      handle_triage
    when :agree
      handle_agree
    else
      @consent.assign_attributes(update_params)
    end

    set_steps # The wizard_steps can change after certain attrs change
    setup_wizard_translated # Next/previous steps can change after steps change

    render_wizard model
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

    session_section_path(@session, section: params[:section], tab: params[:tab])
  end

  def handle_confirm
    ActiveRecord::Base.transaction do
      @triage.process! if @triage&.persisted?

      send_triage_confirmation(@patient_session, @consent)

      if @triage&.new_record?
        # We need to discard the draft triage record so that the patient
        # session can be saved.
        @triage.destroy!
      end

      if @consent.draft_parent.present?
        @consent.draft_parent.recorded_at = Time.zone.now
        @consent.draft_parent.save!
      end

      @consent.recorded_at = Time.zone.now
      @consent.save!
    end

    session.delete(:manage_consents_new_or_existing_parent_id)
  end

  def handle_questions
    questions_attrs = update_params.except(:wizard_step).values
    @consent.health_answers.each_with_index do |ha, index|
      ha.assign_attributes(questions_attrs[index])
    end

    @consent.assign_attributes(wizard_step: current_step)
  end

  def handle_who
    session[:manage_consents_new_or_existing_parent_id] = update_params[
      :new_or_existing_parent
    ]
    @consent.assign_attributes(update_params)
  end

  def handle_parent_details
    @parent_details_form.assign_attributes(parent_details_params)
    @consent.draft_parent = @parent
  end

  def handle_triage
    @triage.assign_attributes(triage_params.merge(performed_by: current_user))
  end

  def handle_agree
    response_was_given = @consent.response_given?
    @consent.assign_attributes(update_params)

    programme = @session.programmes.first # TODO: handle multiple programmes

    if !response_was_given && @consent.response_given?
      @consent.health_answers =
        programme.vaccines.first.health_questions.to_health_answers
      @consent.reason_for_refusal = nil
    elsif response_was_given && !@consent.response_given?
      @consent.health_answers = []
      @consent.reason_for_refusal = nil
    end
  end

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_parent_options
    @parent_options =
      (
        @patient.parents +
          @patient_session.consents.recorded.includes(:parent).map(&:parent)
      ).compact.uniq.sort_by(&:full_name)
  end

  def set_parent
    new_or_existing_parent = session[:manage_consents_new_or_existing_parent_id]
    @parent =
      if new_or_existing_parent == "new"
        @consent.draft_parent || Parent.new
      elsif new_or_existing_parent.present?
        @consent.parent
      end
  end

  def set_parent_relationship
    @parent_relationship = @parent&.relationship_to(patient: @patient)
  end

  def set_parent_details_form
    @parent_details_form =
      ParentDetailsForm.new(
        parent: @parent,
        patient: @patient,
        email: @patient.restricted? ? "" : @parent.email,
        full_name: @parent.full_name,
        phone: @patient.restricted? ? "" : @parent.phone,
        phone_receive_updates: @parent.phone_receive_updates,
        relationship_type: @parent_relationship&.type,
        relationship_other_name: @parent_relationship&.other_name
      )
  end

  def set_consent
    @consent = policy_scope(Consent).find(params[:consent_id])
    @consent.new_or_existing_parent =
      session[:manage_consents_new_or_existing_parent_id]
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_triage
    @triage =
      if policy(Triage).new?
        Triage.find_or_initialize_by(
          patient: @patient,
          programme: @session.programmes.first, # TODO: handle multiple programmes
          organisation: @session.organisation
        )
      end
  end

  def triage_params
    params.fetch(:triage, {}).permit(:status, :notes)
  end

  def update_params
    permitted_attributes = {
      route: %i[route],
      agree: %i[response],
      reason: %i[reason_for_refusal],
      reason_notes: %i[reason_for_refusal_notes],
      questions: questions_params,
      who: %i[new_or_existing_parent]
    }.fetch(current_step)

    params
      .fetch(:consent, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def parent_details_params
    params.require(:parent_details_form).permit(
      :full_name,
      :email,
      :parental_responsibility,
      :phone,
      :phone_receive_updates,
      :relationship_type,
      :relationship_other_name
    )
  end

  # Returns:
  # {
  #   question_0: %i[notes response],
  #   question_1: %i[notes response],
  #   question_2: %i[notes response],
  #   ...
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

    @consent.assign_attributes(triage_allowed: policy(Triage).new?)

    self.steps = @consent.wizard_steps
  end
end
