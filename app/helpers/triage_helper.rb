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

  def triage_form_status_options
    Triage.statuses.keys.map do |status|
      [status, Triage.human_enum_name(:status, status)]
    end
  end

  def in_tab_needs_triage?(action, _outcome)
    action.in? %i[triage follow_up]
  end

  def in_tab_triage_complete?(action, _outcome)
    action.in? %i[vaccinate]
  end

  def in_tab_get_consent?(action, _outcome)
    action.in? %i[get_consent]
  end

  def in_tab_no_triage_needed?(action, outcome)
    action.in?(%i[vaccinate check_refusal]) || outcome.in?(%i[vaccinated])
  end
end
