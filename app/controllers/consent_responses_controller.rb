class ConsentResponsesController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_draft_consent_response

  layout "two_thirds"

  def new
    render :edit_who
  end

  def create
    health_questions = ConsentResponse::HEALTH_QUESTIONS
            .fetch(:hpv)
            .map { |question| { question: } }

    if consent_response_who_params.present?
      @draft_consent_response.assign_attributes(
        consent_response_who_params.merge(
          route: "phone",
          health_questions:
        )
      )
      if @draft_consent_response.save(context: :edit_who)
        redirect_to action: :edit_consent
      else
        render :edit_who
      end
    else
      # If the params are missing, assume this is the Gillick competence route.
      # This feels like it could be more explicit.
      @draft_consent_response.update!(
        route: "self_consent",
        health_questions:
      )

      redirect_to action: :edit_gillick
    end
  end

  def update
    if consent_response_gillick_params.present?
      @draft_consent_response.assign_attributes(consent_response_gillick_params)
      if @draft_consent_response.save(context: :edit_gillick)
        redirect_to action: :edit_consent
      else
        render :edit_gillick
      end
    end

    if consent_response_agree_params.present?
      @draft_consent_response.assign_attributes(consent_response_agree_params)
      if @draft_consent_response.save(context: :edit_consent)
        # Reset the reason for refusal so the user has to pick it again.
        # Otherwise it will be pre-filled with the previous value.
        @draft_consent_response.update! reason_for_refusal: nil

        if @draft_consent_response.consent_given?
          redirect_to action: :edit_questions
        elsif @draft_consent_response.consent_refused?
          redirect_to action: :edit_reason
        else
          redirect_to action: :edit_confirm
        end
      else
        render :edit_consent
      end
    end

    if consent_response_reason_params.present?
      @draft_consent_response.assign_attributes(consent_response_reason_params)
      if @draft_consent_response.save(context: :edit_reason)
        redirect_to action: :edit_confirm
      else
        render :edit_reason
      end
    end

    if consent_response_health_questions_params.present?
      @draft_consent_response.health_questions.each_with_index do |hq, index|
        hq.merge! consent_response_health_questions_params["question_#{index}"]
      end

      # TODO: Handle validation
      @draft_consent_response.save!

      redirect_to action: :edit_confirm
    end
  end

  def assessing_gillick
  end

  def edit_who
  end

  def edit_gillick
  end

  def edit_consent
  end

  def edit_reason
  end

  def edit_questions
  end

  def edit_confirm
  end

  def record
    unless @draft_consent_response.consent_not_provided?
      ActiveRecord::Base.transaction do
        @draft_consent_response.update!(recorded_at: Time.zone.now)
        @patient_session.do_consent!
      end
    end

    redirect_to triage_session_path(@session),
                flash: {
                  success: {
                    title: "Consent saved for #{@patient.full_name}",
                    body: ActionController::Base.helpers.link_to(
                      "View child record",
                      session_patient_triage_path(@session, @patient)
                    ),
                  },
                }
  end

  private

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_draft_consent_response
    @draft_consent_response = @patient
      .consent_responses
      .find_or_initialize_by(recorded_at: nil, campaign: @session.campaign)
  end

  def consent_response_who_params
    params.fetch(:consent_response, {}).permit(
      :parent_name,
      :parent_phone,
      :parent_relationship,
      :parent_relationship_other,
    )
  end

  def consent_response_gillick_params
    params.fetch(:consent_response, {}).permit(
      :gillick_competent,
      :gillick_competence_details,
    )
  end

  def consent_response_agree_params
    params.fetch(:consent_response, {}).permit(
      :consent,
    )
  end

  def consent_response_reason_params
    params.fetch(:consent_response, {}).permit(
      :reason_for_refusal,
      :reason_for_refusal_other,
    )
  end

  def consent_response_health_questions_params
    params.fetch(:consent_response, {}).permit(
      question_0: [:notes, :response],
      question_1: [:notes, :response],
      question_2: [:notes, :response],
      question_3: [:notes, :response],
    )
  end
end
