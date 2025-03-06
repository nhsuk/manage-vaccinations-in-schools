# frozen_string_literal: true

class AppOutcomeBannerComponent < ViewComponent::Base
  def initialize(patient_session:, programme:, current_user: nil)
    super

    @patient_session = patient_session
    @programme = programme
    @current_user = current_user
  end

  def call
    render AppCardComponent.new(colour:) do |c|
      c.with_heading { heading }
      govuk_summary_list(rows:)
    end
  end

  def status
    @status ||= @patient_session.status(programme:)
  end

  private

  attr_reader :programme

  def rows
    data =
      if vaccination_record&.administered?
        [
          ["Vaccine", vaccine_summary],
          ["Site", vaccination_record.human_enum_name(:delivery_site)],
          ["Date", date_summary],
          ["Time", last_action_time.to_fs(:time)],
          ["Location", location],
          ["Vaccinator", clinician_name],
          ["Notes", notes]
        ]
      else
        [
          ["Reason", reason_do_not_vaccinate],
          ["Date", date_summary],
          ["Time", last_action_time.to_fs(:time)],
          (["Location", location] if show_location?),
          ["Decided by", clinician_name],
          ["Notes", notes]
        ]
      end
    data.compact.map do |key, value|
      { key: { text: key }, value: { text: value } }
    end
  end

  def vaccination_record
    @vaccination_record ||=
      begin
        vaccination_records = @patient_session.outcome.all(programme:)
        if @patient_session.outcome.status[programme] ==
             PatientSession::Outcome::VACCINATED
          vaccination_records.select(&:administered?).last
        else
          vaccination_records.last
        end
      end
  end

  def triage
    @triage ||= @patient_session.triage.latest(programme:)
  end

  def show_location?
    # location only makes sense if an attempt to vaccinate on site was made
    vaccination_record.present?
  end

  def vaccine_summary
    type = vaccination_record.programme.name
    brand = vaccination_record.vaccine.brand
    batch = vaccination_record.batch.name
    "#{type} (#{brand}, #{batch})"
  end

  def reason_do_not_vaccinate
    key =
      if vaccination_record&.not_administered?
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{vaccination_record.outcome}"
      else
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{status}"
      end
    I18n.t(key, full_name: @patient_session.patient.full_name)
  end

  def clinician_name
    if clinician == @current_user
      "You (#{clinician.full_name})"
    else
      clinician&.full_name || "Unknown"
    end
  end

  def clinician
    @clinician ||= (vaccination_record || triage).performed_by
  end

  def location
    @location ||=
      vaccination_record.location_name || @patient_session.location.name
  end

  def notes
    (vaccination_record&.notes || triage&.notes).presence || "None"
  end

  def date_summary
    date = last_action_time.to_date

    if date == Time.zone.today
      "Today (#{date.to_fs(:long)})"
    else
      date.to_fs(:long)
    end
  end

  def last_action_time
    @last_action_time ||= vaccination_record&.performed_at || triage&.created_at
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end
end
