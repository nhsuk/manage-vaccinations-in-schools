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
end
