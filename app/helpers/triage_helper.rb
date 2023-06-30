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

  def parent_relationship(consent_response)
    if consent_response.parent_relationship == "other"
      consent_response.parent_relationship_other
    else
      ConsentResponse.human_enum_name(
        "parent_relationship",
        consent_response.parent_relationship
      )
    end
  end

  def triage_form_status_options
    Triage.statuses.keys.map do |status|
      [status, Triage.human_enum_name(:status, status)]
    end
  end
end
