class PatientTriageStatusService
  def self.call(consent:, triage:)
    if consent&.consent_refused?
      :refused_consent
    elsif triage.present?
      case triage.status
      when "do_not_vaccinate"
        :do_not_vaccinate
      when "ready_for_session"
        :ready_for_session
      when "needs_follow_up"
        :needs_follow_up
      when "to_do"
        :to_do
      when "no_response"
        :no_response
      end
    elsif consent.present?
      :to_do
    else
      :no_response
    end
  end
end
