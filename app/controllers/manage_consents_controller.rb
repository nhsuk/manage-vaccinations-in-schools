class ManageConsentsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_route
  before_action :set_session
  before_action :set_patient
  before_action :set_consent, except: %i[create]
  before_action :set_steps, except: %i[create]
  before_action :setup_wizard_translated, except: %i[create]
  before_action :set_triage,
                except: %i[create],
                if: -> { step.in?(%w[questions confirm]) }

  def create
    consent =
      Consent.create!(
        patient: @patient,
        campaign: @session.campaign,
        route: "phone",
        health_answers: @session.health_questions.to_health_answers
      )

    redirect_to action: :show, id: :who, consent_id: consent.id
  end

  def show
    render_wizard
  end

  def update
    if current_step == :confirm
      # TODO: Handle the final step of the manage consent journey.
      # Something like:
      #
      # ActiveRecord::Base.transaction do
      #   @draft_consent.recorded_at = Time.zone.now
      #   @draft_consent.save!(validate: false)
      #   @patient_session.do_consent!
      #   @patient_session.do_triage! if @patient_session.triage.present?
      # end
      #
      # Plus a flash and redirect to the right location.
    elsif current_step == :questions
      # triage_attrs = update_params.delete(:triage) # TODO: Update @triage
      questions_attrs = update_params.except(:triage, :form_step).values

      @consent.health_answers.each_with_index do |ha, index|
        ha.assign_attributes(questions_attrs[index])
      end

      @consent.assign_attributes(form_step: current_step)
    else
      @consent.assign_attributes(update_params)
    end

    set_steps # The form_steps can change after certain attrs change
    setup_wizard_translated # Next/previous steps can change after steps change

    render_wizard @consent
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def finish_wizard_path
    redirect_path =
      case @route
      when "consents"
        consents_session_path(@session)
      when "triage"
        triage_session_path(@session)
      else
        vaccinations_session_path(@session)
      end

    flash[:success] = {
      heading: "Record saved for #{@patient.full_name}",
      body:
        ActionController::Base.helpers.link_to(
          "View child record",
          session_patient_triage_path(@session, @patient)
        )
    }
    redirect_path
  end

  def set_route
    @route = params[:route]
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_consent
    @consent = Consent.find(params[:consent_id])
  end

  def set_triage
    patient_session = @patient.patient_sessions.find_by(session: @session)
    @triage = Triage.find_or_initialize_by(patient_session:)
  end

  def update_params
    permitted_attributes = {
      who: %i[
        parent_name
        parent_phone
        parent_relationship
        parent_relationship_other
      ],
      agree: %i[response],
      reason: %i[reason_for_refusal reason_for_refusal_other],
      questions: questions_params
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

    Array
      .new(n) { |index| ["question_#{index}", %i[notes response]] }
      .to_h
      .merge(triage: %i[notes status])
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @consent.form_steps
  end
end
