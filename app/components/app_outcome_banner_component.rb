class AppOutcomeBannerComponent < ViewComponent::Base
  delegate :vaccination_record, :state, to: :@patient_session

  def initialize(patient_session:, current_user: nil)
    super

    @patient_session = patient_session
    @current_user = current_user
  end

  def call
    render AppCardComponent.new(heading:, feature: true, colour:) do
      govuk_summary_list(classes: "app-summary-list--no-bottom-border", rows:)
    end
  end

  private

  def rows
    data =
      if @patient_session.vaccinated?
        [
          ["Vaccine", vaccine_summary],
          ["Site", vaccination_record.human_enum_name(:delivery_site)],
          ["Date", date_summary],
          ["Time", last_action_time.to_fs(:time)],
          ["Location", @patient_session.session.location.name],
          ["Vaccinator", clinician_name],
          ["Notes", notes]
        ]
      else
        [
          ["Reason", reason_do_not_vaccinate],
          ["Date", date_summary],
          ["Time", last_action_time.to_fs(:time)],
          (
            if show_location?
              ["Location", @patient_session.session.location.name]
            end
          ),
          ["Decided by", clinician_name],
          ["Notes", notes]
        ]
      end
    data.compact.map do |key, value|
      { key: { text: key }, value: { text: value } }
    end
  end

  def show_location?
    # showing the location only makes sense if an attempt to vaccinate on site was made
    @patient_session.vaccination_records.recorded.any?
  end

  def vaccine_summary
    type = vaccination_record.vaccine.type
    brand = vaccination_record.vaccine.brand
    batch = vaccination_record.batch.name
    "#{type} (#{brand}, #{batch})"
  end

  def reason_do_not_vaccinate
    key =
      if vaccination_record&.reason.present?
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{vaccination_record.reason}"
      else
        "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{@patient_session.state}"
      end
    I18n.t(key, full_name: @patient_session.patient.full_name)
  end

  def clinician_name
    if clinician == @current_user
      "You (#{clinician.full_name})"
    else
      clinician.full_name
    end
  end

  def clinician
    @clinician ||= (vaccination_record || most_recent_triage).user
  end

  def notes
    (vaccination_record&.notes || most_recent_triage&.notes).presence || "None"
  end

  def date_summary
    if last_action_time.to_date == Time.zone.today
      "Today (#{last_action_time.to_fs(:nhsuk_date)})"
    else
      last_action_time.to_fs(:nhsuk_date)
    end
  end

  def last_action_time
    @last_action_time ||=
      vaccination_record&.recorded_at || most_recent_triage&.created_at
  end

  def most_recent_triage
    @most_recent_triage ||= @patient_session.triage.order(:created_at).last
  end

  def heading
    I18n.t("patient_session_statuses.#{state}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{state}.colour")
  end
end
