# frozen_string_literal: true

module VaccinationsHelper
  def vaccination_date(datetime)
    date = datetime.to_date

    current_date = Time.zone.today

    if date == current_date
      "Today (#{date.to_fs(:long)})"
    elsif date == current_date - 1
      "Yesterday (#{date.to_fs(:long)})"
    else
      date.to_fs(:long)
    end
  end

  def vaccination_delivery_methods_for(vaccine)
    vaccine.available_delivery_methods.map do |m|
      [m, VaccinationRecord.human_enum_name("delivery_methods", m)]
    end
  end

  def vaccination_delivery_sites_for(vaccine)
    vaccine.available_delivery_sites.map do |s|
      [s, VaccinationRecord.human_enum_name("delivery_sites", s)]
    end
  end

  def in_tab_action_needed?(action, _outcome)
    action.in? %i[vaccinate get_consent triage follow_up check_refusal]
  end

  def in_tab_vaccinated?(_action, outcome)
    outcome.in? %i[vaccinated]
  end

  def in_tab_not_vaccinated?(_action, outcome)
    outcome.in? %i[do_not_vaccinate not_vaccinated]
  end
end
