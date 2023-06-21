module VaccinationsHelper
  def vaccination_status_colour(status)
    case status
    when "no_outcome"
      :white
    when "vaccinated"
      :green
    when "no_consent"
      :red
    when "could_not_vaccinate"
      :orange
    else
      :white
    end
  end

  def vaccination_status_icon(status)
    case status
    when "no_consent", "couldnt_vaccinate"
      "cross"
    when "vaccinated"
      "tick"
    end
  end
end
