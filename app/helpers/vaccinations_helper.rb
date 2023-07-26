module VaccinationsHelper
  def vaccination_date(datetime)
    date = datetime.to_date

    current_date = Time.zone.today

    if date == current_date
      "Today (#{date.to_fs(:nhsuk_date)})"
    elsif date == current_date - 1
      "Yesterday (#{date.to_fs(:nhsuk_date)})"
    else
      date.to_fs(:nhsuk_date)
    end
  end

  def vaccination_not_given_reason(record)
    case record.reason
    when "refused"
      "#{record.patient_session.patient.full_name} refused it"
    when "not_well"
      "#{record.patient_session.patient.full_name} was not well enough"
    when "contraindications"
      "#{record.patient_session.patient.full_name} had contraindications"
    when "already_had"
      "#{record.patient_session.patient.full_name} has already had the vaccine"
    when "absent_from_school"
      "#{record.patient_session.patient.full_name} was absent from school"
    when "absent_from_session"
      "#{record.patient_session.patient.full_name} was absent from the session"
    else
      "Unknown"
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
