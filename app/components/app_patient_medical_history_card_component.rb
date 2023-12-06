class AppPatientMedicalHistoryCardComponent < ViewComponent::Base
  def initialize(patient:, consent:, triage:)
    super

    @patient = patient
    # HACK: This needs to work with multiple consents
    @consent = consent
    @triage = triage
  end

  def triage_present?
    @triage.blank? || !@triage.persisted?
  end

  def reasons_triage_needed
    @consent&.reasons_triage_needed
  end
end
