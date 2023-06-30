module VaccinationsHelper
  def vaccination_action_colour(action_or_outcome)
    case action_or_outcome
    when :get_consent
      :yellow
    when :check_refusal
      :orange
    when :vaccinated
      :green
    when :not_vaccinated
      :orange
    when :vaccinate
      :purple
    when :triage
      :blue
    when :follow_up
      :"aqua-green"
    when :do_not_vaccinate
      :red
    when :unknown
      :white
    else
      :white
    end
  end

  def vaccination_site_options
    VaccinationRecord.sites.map do |k, id|
      OpenStruct.new(id:, name: k.humanize)
    end
  end
end
