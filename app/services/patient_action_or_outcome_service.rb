class PatientActionOrOutcomeService
  def self.call(consent:, triage:, vaccination_record:)
    if consent.nil?
      { action: :get_consent }
    elsif consent&.consent_refused?
      { action: :check_refusal }
    elsif vaccination_record&.administered?
      { outcome: :vaccinated }
    elsif !vaccination_record&.administered.nil?
      { outcome: :not_vaccinated }
    elsif !consent.triage_needed?
      { action: :vaccinate }
    elsif triage.blank?
      { action: :triage }
    elsif triage&.ready_to_vaccinate?
      { action: :vaccinate }
    elsif triage&.needs_follow_up?
      { action: :follow_up }
    elsif triage&.do_not_vaccinate?
      { outcome: :do_not_vaccinate }
    else
      { outcome: :unknown }
    end
  end
end
