class ConsentResponsesController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_draft_consent_response

  layout "two_thirds"

  def create
    @draft_consent_response.update!(
      campaign: @session.campaign,
      parent_name: "Test Parent",
      parent_phone: "07412 345678",
      parent_email: "test.parent@example.com",
      parent_relationship: "mother",
      route: "website",
      health_questions: ConsentResponse::HEALTH_QUESTIONS
        .fetch(:hpv)
        .map { |question| { question: } }
    )

    redirect_to action: :edit_agree
  end

  def update
    if consent_response_agree_params.present?
      @draft_consent_response.assign_attributes(consent_response_agree_params)
      if @draft_consent_response.save(context: :edit_consent)
        redirect_to action: :edit_questions
      else
        render :edit_agree
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

  def edit_agree
  end

  def edit_questions
  end

  def edit_confirm
  end

  def record
    ActiveRecord::Base.transaction do
      @draft_consent_response.update!(recorded_at: Time.zone.now)
      @patient_session.do_consent!
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
      .find_or_initialize_by(recorded_at: nil)
  end

  def consent_response_agree_params
    params.fetch(:consent_response, {}).permit(
      :consent,
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
