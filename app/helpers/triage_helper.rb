module TriageHelper
  def triage_status_colour(triage_status:)
    {
      refused_consent: :red,
      do_not_vaccinate: :red,
      needs_follow_up: :blue,
      no_response: :white,
      ready_to_vaccinate: :green
    }.with_indifferent_access.fetch(triage_status, :grey)
  end

  def triage_status_icon(triage_status:)
    {
      refused_consent: "cross",
      do_not_vaccinate: "cross",
      ready_to_vaccinate: "tick"
    }.with_indifferent_access[
      triage_status
    ]
  end

  def in_tab_needs_triage?(patient_session)
    patient_session.state.in? %w[consent_given_triage_needed]
  end

  def in_tab_triage_complete?(patient_session)
    patient_session.state.in? %w[
                                triaged_ready_to_vaccinate
                                triaged_do_not_vaccinate
                              ]
  end

  def in_tab_get_consent?(patient_session)
    patient_session.state.in? %w[added_to_session]
  end

  def in_tab_no_triage_needed?(patient_session)
    patient_session.state.in? %w[
                                consent_refused
                                consent_given_triage_not_needed
                                vaccinated
                                unable_to_vaccinate
                              ]
  end
end
