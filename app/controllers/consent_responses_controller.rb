class ConsentResponsesController < ApplicationController
  before_action :set_session
  before_action :set_patient

  layout "two_thirds"

  def confirm
    @draft_consent_response = @patient
      .consent_responses
      .find_or_initialize_by(recorded_at: nil)

    @draft_consent_response.update!(
      campaign: @session.campaign,
      parent_name: "Test Parent",
      parent_phone: "07412 345678",
      parent_email: "test.parent@example.com",
      parent_relationship: "mother",
      consent: "given",
      route: "website",
      health_questions: [
        {"question"=>"Does the child have any severe allergies that have led to an anaphylactic reaction?",
         "response"=>"no"},
        {"question"=>"Does the child have any existing medical conditions?",
         "response"=>"no"},
        {"question"=>"Does the child take any regular medication?",
         "response"=>"no"},
        {"question"=>"Is there anything else we should know?",
         "response"=>"no"}
      ],
    )
  end

  private

  def set_session
    @session = Session.find(params.fetch(:session_id) { params.fetch(:id) })
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:id])
  end
end
