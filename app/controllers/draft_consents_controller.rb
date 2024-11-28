# frozen_string_literal: true

class DraftConsentsController < ApplicationController
  include TriageMailerConcern

  skip_after_action :verify_policy_scoped

  before_action :set_draft_consent
  before_action :set_patient_session
  before_action :set_patient
  before_action :set_session
  before_action :set_programme
  before_action :set_parent
  before_action :set_triage
  before_action :set_consent

  include WizardControllerConcern

  before_action :set_parent_options, if: -> { current_step == :who }

  after_action :verify_authorized

  def show
    authorize Consent, :edit?

    render_wizard
  end

  def update
    authorize Consent

    case current_step
    when :questions
      handle_questions
    when :confirm
      handle_confirm
    else
      @draft_consent.assign_attributes(update_params)
    end

    jump_to("confirm") if @draft_consent.editing? && current_step != :confirm

    set_steps
    setup_wizard_translated

    render_wizard @draft_consent
  end

  private

  def handle_confirm
    return unless @draft_consent.save

    @draft_consent.write_to!(@consent, triage: @triage)

    ActiveRecord::Base.transaction do
      @triage&.save! if @draft_consent.response_given?
      @consent.parent&.save!
      @consent.save!
    end

    send_triage_confirmation(@patient_session, @consent)

    tab = @consent.response_given? ? "given" : "refused"

    heading_link_href =
      session_patient_path(@session, id: @patient.id, section: "consents", tab:)

    flash[:success] = {
      heading: "Consent recorded for",
      heading_link_text: @patient.full_name,
      heading_link_href:
    }
  end

  def handle_questions
    questions_attrs = update_params.except(:wizard_step).values
    @draft_consent.health_answers.each_with_index do |ha, index|
      ha.assign_attributes(questions_attrs[index])
    end

    @draft_consent.assign_attributes(wizard_step: current_step)
  end

  def finish_wizard_path
    session_consents_path(@session)
  end

  def update_params
    permitted_attributes = {
      agree: %i[response],
      notes: %i[notes],
      notify_parents: %i[notify_parents],
      parent_details: %i[
        parent_email
        parent_full_name
        parent_phone
        parent_phone_receive_updates
        parent_relationship_other_name
        parent_relationship_type
        parent_responsibility
      ],
      questions: questions_params,
      reason: %i[reason_for_refusal],
      route: %i[route],
      who: %i[new_or_existing_contact],
      triage: %i[triage_status triage_notes]
    }.fetch(current_step)

    params
      .fetch(:draft_consent, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def set_draft_consent
    @draft_consent = DraftConsent.new(request_session: session, current_user:)
  end

  def set_patient_session
    @patient_session = @draft_consent.patient_session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_session
    @session = @patient_session.session
  end

  def set_programme
    @programme = @draft_consent.programme
  end

  def set_parent
    @parent = @draft_consent.parent
  end

  def set_triage
    @triage =
      if policy(Triage).new?
        Triage.not_invalidated.find_or_initialize_by(
          patient: @patient,
          programme: @draft_consent.programme,
          organisation: @session.organisation
        )
      end
  end

  def set_consent
    @consent = @draft_consent.consent || Consent.new
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @draft_consent.wizard_steps
  end

  def set_parent_options
    @parent_options =
      (@patient.parents + @patient_session.consents.filter_map(&:parent))
        .compact
        .uniq
        .sort_by(&:label)
  end

  # Returns:
  # {
  #   question_0: %i[notes response],
  #   question_1: %i[notes response],
  #   question_2: %i[notes response],
  #   ...
  # }
  def questions_params
    n = @draft_consent.health_answers&.size || 0
    Array.new(n) { |index| ["question_#{index}", %i[notes response]] }.to_h
  end
end
