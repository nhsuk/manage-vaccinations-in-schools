class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient_session)
    super

    @patient_session = patient_session
  end

  def events_by_day
    all_events
      .sort_by { -_1[:time].to_i }
      .group_by { _1[:time].to_fs(:nhsuk_date) }
  end

  def all_events
    [vaccination_events, triage_events, consent_events, session_events].flatten
  end

  def vaccination_events
    @patient_session.vaccination_records.map do
      {
        title: "Vaccinated with #{helpers.vaccine_heading(_1.vaccine)}",
        time: _1.created_at,
        by: _1.user.full_name
      }
    end
  end

  def triage_events
    @patient_session.triage.map do
      {
        title: "Triage decision: #{_1.human_enum_name(:status)}",
        time: _1.created_at,
        by: _1.user.full_name
      }
    end
  end

  def consent_events
    @patient_session.patient.consents.recorded.map do
      {
        title:
          "Consent #{_1.response} by #{_1.parent_name} (#{_1.who_responded})",
        time: _1.recorded_at
      }
    end
  end

  def session_events
    [
      {
        title:
          "Invited to session at #{@patient_session.session.location.name}",
        time: @patient_session.created_at
      }
    ]
  end
end
