class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient_session)
    super

    @patient_session = patient_session
  end

  def events_by_day
    consent_events.group_by { _1[:time].to_fs(:nhsuk_date) }
  end

  def consent_events
    @patient_session
      .patient
      .consents
      .recorded
      .order(recorded_at: :desc)
      .map do |consent|
        {
          title:
            "Consent #{consent.response} by #{consent.parent_name} (#{consent.who_responded})",
          time: consent.recorded_at
        }
      end
  end
end
