class AppPatientMedicalHistoryCardComponent < ViewComponent::Base
  def initialize(patient:, consent_response:, triage:)
    super

    @patient = patient
    @consent_response = consent_response
    @triage = triage
  end

  def triage_present?
    @triage.blank? || !@triage.persisted?
  end

  def reasons_triage_needed
    reasons = []
    if @consent_response.parent_relationship_other?
      reasons << "Check parental responsibility"
    end
    if @consent_response.health_questions_require_follow_up?
      reasons << "Notes need triage"
    end
    reasons
  end
end
