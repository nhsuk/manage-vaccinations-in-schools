class ConsentResponsesController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_draft_consent_response

  layout "two_thirds"

  def confirm
    @draft_consent_response.update!(
      campaign: @session.campaign,
      parent_name: "Test Parent",
      parent_phone: "07412 345678",
      parent_email: "test.parent@example.com",
      parent_relationship: "mother",
      consent: "given",
      route: "website",
      health_questions: ConsentResponse::HEALTH_QUESTIONS
        .fetch(:hpv)
        .map do |question|
          { question:, response: "no" }
        end
    )
  end

  def record
    @draft_consent_response.update!(recorded_at: Time.zone.now)
    @patient_session.do_consent!

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
end
