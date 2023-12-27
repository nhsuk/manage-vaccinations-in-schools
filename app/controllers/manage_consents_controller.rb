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
  before_action :set_patient_session,
                except: %i[create],
                if: -> { step.in?(%w[gillick questions confirm]) }
  before_action :set_triage,
                except: %i[create],
                if: -> { step.in?(%w[questions confirm]) }

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
      ActiveRecord::Base.transaction do
        @consent.recorded_at = Time.zone.now
        @consent.save!
        @patient_session.do_consent!
        @patient_session.do_triage!
      end
    when :gillick
      @patient_session.update! gillick_params

      @consent.assign_attributes(
        patient_session: @patient_session,
        form_step: current_step
      )
    when :questions
      questions_attrs = update_params.except(:triage, :form_step).values
      @consent.health_answers.each_with_index do |ha, index|
        ha.assign_attributes(questions_attrs[index])
      end

      triage_attrs = update_params.delete(:triage).merge(user: current_user)
      @triage.update! triage_attrs

      @consent.assign_attributes(triage: @triage, form_step: current_step)
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
    flash[:success] = {
      heading: "Record saved for #{@patient.full_name}",
      body:
        ActionController::Base.helpers.link_to(
          "View child record",
          session_patient_triage_path(@session, @patient)
        )
    }

    case @route
    when "consents"
      consents_session_path(@session)
    when "triage"
      triage_session_path(@session)
    else
      vaccinations_session_path(@session)
    end
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

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_triage
    @triage = Triage.find_or_initialize_by(patient_session: @patient_session)
  end

  def create_params
    {
      patient: @patient,
      campaign: @session.campaign,
      route: params.permit(:consent)[:consent],
      health_answers: @session.health_questions.to_health_answers
    }
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
      reason: %i[reason_for_refusal reason_for_refusal_other],
      questions: questions_params
    }.fetch(current_step)

    params
      .fetch(:consent, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def gillick_params
    params.fetch(:patient_session, {}).permit(
      :gillick_competent,
      :gillick_competence_notes
    )
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
