module TriageHelper
  def triage_status_colour(status)
    case status
    when "do_not_vaccinate"
      :red
    when "ready_for_session"
      :green
    when "needs_follow_up"
      :blue
    when "to_do"
      :grey
    when "no_response"
      :white
    else
      :white
    end
  end

  def triage_status_icon(status)
    case status
    when "do_not_vaccinate"
      "cross"
    when "ready_for_session"
      "tick"
    end
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
end
