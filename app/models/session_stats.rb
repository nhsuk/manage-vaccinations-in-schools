class SessionStats
  def initialize(patient_sessions:, location:)
    @patient_sessions = patient_sessions
    @location = location
  end

  def call
    counts = {
      with_consent_given: 0,
      with_consent_refused: 0,
      without_a_response: 0,
      needing_triage: 0,
      ready_to_vaccinate: 0,
      unmatched_responses: @location.consent_forms.unmatched.count
    }

    @patient_sessions.each do |s|
      counts[:with_consent_given] += 1 if s.consent_given?
      counts[:with_consent_refused] += 1 if s.consent_refused?
      counts[:without_a_response] += 1 if s.no_consent?

      if s.consent_given_triage_needed? || s.triaged_kept_in_triage?
        counts[:needing_triage] += 1
      end

      counts[:ready_to_vaccinate] += 1 if s.triaged_ready_to_vaccinate? ||
        s.consent_given_triage_not_needed?
    end

    counts
  end
end
