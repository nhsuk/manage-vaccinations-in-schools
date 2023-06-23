class PatientTriageStatusService
  def self.call(consent:, triage:)
    if consent&.consent_refused?
      :refused_consent
    elsif triage.present?
      triage.status
    elsif consent.present?
      :to_do
    else
      :no_response
    end
  end
end
