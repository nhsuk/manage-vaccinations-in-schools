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
    @status ||= patient_session.status(programme:)
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

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
      patient
        .vaccination_records
        .includes(:batch, :performed_by_user, :vaccine)
        .order(performed_at: :desc)
        .find_by(programme:)
  end

  def triage
    @triage ||=
      patient
        .triages
        .not_invalidated
        .includes(:performed_by)
        .order(created_at: :desc)
        .find_by(programme:)
  end

  def session_attendance
    @session_attendance ||= patient_session.todays_attendance
  end

  def show_location?
    # location only makes sense if an attempt to vaccinate on site was made
    vaccination_record.present?
  end

  def vaccine_summary
    type = programme.name
    batch = vaccination_record.batch&.name
    brand =
      (vaccination_record.vaccine || vaccination_record.batch&.vaccine)&.brand

    if brand.present? && batch.present?
      "#{type} (#{brand}, #{batch})"
    elsif brand.present?
      "#{type} (#{brand})"
    elsif batch.present?
      "#{type} (#{batch})"
    else
      type
    end
  end

  def reason_do_not_vaccinate
    key =
      if vaccination_record&.not_administered?
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{vaccination_record.outcome}"
      elsif session_attendance&.attending == false
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.absent_from_session"
      else
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{status}"
      end
    I18n.t(key, full_name: patient.full_name)
  end

  def clinician_name
    if clinician == @current_user
      "You (#{clinician.full_name})"
    else
      clinician&.full_name || "Unknown"
    end
  end

  def clinician
    @clinician ||= (vaccination_record || triage)&.performed_by
  end

  def location
    @location ||=
      vaccination_record.location_name || patient_session.session.location.name
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
    @last_action_time ||=
      vaccination_record&.performed_at || triage&.created_at ||
        session_attendance&.created_at
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end
end
