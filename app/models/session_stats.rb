class SessionStats
  def initialize(patient_sessions:, session:)
    @patient_sessions = patient_sessions
    @session = session

    @stats = calculate_stats
  end

  def [](key)
    @stats[key]
  end

  def to_h
    @stats
  end

  private

  def calculate_stats
    counts = {
      with_consent_given: 0,
      with_consent_refused: 0,
      without_a_response: 0,
      needing_triage: 0,
      vaccinated: 0,
      could_not_vaccinate: 0,
      with_conflicting_consent: 0,
      unmatched_responses: @session.consent_forms.unmatched.recorded.count
    }

    @patient_sessions.each do |s|
      counts[:with_consent_given] += 1 if s.consent_given?
      counts[:with_consent_refused] += 1 if s.consent_refused?
      counts[:with_conflicting_consent] += 1 if s.consent_conflicts?
      counts[:without_a_response] += 1 if s.no_consent?

      if s.consent_given_triage_needed? || s.triaged_kept_in_triage?
        counts[:needing_triage] += 1
      end

      counts[:vaccinated] += 1 if s.vaccinated?
      counts[:could_not_vaccinate] += 1 if s.delay_vaccination? ||
        s.consent_refused? || s.consent_conflicts? ||
        s.triaged_do_not_vaccinate? || s.unable_to_vaccinate? ||
        s.unable_to_vaccinate_not_gillick_competent?
    end

    counts
  end
end
