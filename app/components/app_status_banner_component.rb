class AppStatusBannerComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(heading: title, feature: true, colour:) do
      status_contents
    end %>
  ERB
  def initialize(patient_session:, current_user: nil)
    super

    @patient_session = patient_session
    @current_user = current_user
  end

  def title
    I18n.t(
      "patient_session_statuses.#{state}.banner_title",
      full_name:,
      who_responded:
    )
  end

  def explanation
    if state == "unable_to_vaccinate"
      reason_for_refusal =
        I18n.t(
          "patient_session_statuses.#{state}.banner_explanation.#{vaccination_record.reason}",
          full_name:
        )
      gave_consent =
        I18n.t(
          "patient_session_statuses.#{state}.banner_explanation.gave_consent",
          who_responded:
        )

      "#{reason_for_refusal}\n<br />\n#{gave_consent}".html_safe
    else
      I18n.t(
        "patient_session_statuses.#{state}.banner_explanation",
        default: "",
        full_name:,
        triage_nurse:,
        who_responded:,
        who_refused:
      )
    end
  end

  def colour
    I18n.t("patient_session_statuses.#{state}.colour")
  end

  private

  def consent
    # HACK: Component needs to be updated to work with multiple consents.
    @consent ||= @patient_session.consents.first
  end

  def vaccination_record
    @vaccination_record ||= @patient_session.vaccination_record
  end

  def triage
    @triage ||= @patient_session.triage.order(:created_at).last
  end

  def who_responded
    consent&.who_responded&.downcase
  end

  def who_refused
    @patient_session
      .consents
      .response_refused
      .map(&:who_responded)
      .last
      &.capitalize
  end

  def full_name
    @patient_session.patient.full_name
  end

  def triage_nurse
    triage&.user&.full_name
  end

  def state
    @patient_session.state
  end

  def status_contents
    if state == "vaccinated"
      vaccinated_status_contents
    elsif state.in? %w[triaged_do_not_vaccinate unable_to_vaccinate]
      do_not_vaccinate_status_contents
    else
      tag.p { explanation }
    end
  end

  def vaccine_summary
    type = vaccination_record.vaccine.type
    brand = vaccination_record.vaccine.brand
    batch = vaccination_record.batch.name
    "#{type} (#{brand}, #{batch})"
  end

  def last_action
    case state
    when "vaccinated", "unable_to_vaccinate"
      :vaccination
    when "triaged_do_not_vaccinate"
      :triage
    end
  end

  def last_action_time
    @last_action_time ||=
      if last_action == :vaccination
        vaccination_record.recorded_at
      elsif last_action == :triage
        triage.created_at
      end
  end

  def date_summary
    if last_action_time.to_date == Time.zone.today
      "Today (#{last_action_time.to_fs(:nhsuk_date)})"
    else
      last_action_time.to_fs(:nhsuk_date)
    end
  end

  def nurse
    @nurse ||=
      if last_action == :triage
        triage&.user
      elsif last_action == :vaccination
        vaccination_record&.user
      end
  end

  def nurse_name_summary
    if nurse == @current_user
      "You (#{nurse.full_name})"
    else
      nurse.full_name
    end
  end

  def notes
    (vaccination_record&.notes || triage&.notes).presence || "None"
  end

  def vaccinated_status_contents
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Vaccine" }
        row.with_value { vaccine_summary }
      end

      summary_list.with_row do |row|
        row.with_key { "Site" }
        row.with_value { vaccination_record.human_enum_name(:delivery_site) }
      end

      summary_list.with_row do |row|
        row.with_key { "Date" }
        row.with_value { date_summary }
      end

      summary_list.with_row do |row|
        row.with_key { "Time" }
        row.with_value { last_action_time.to_fs(:time) }
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { @patient_session.session.location.name }
      end

      summary_list.with_row do |row|
        row.with_key { "Nurse" }
        row.with_value { nurse_name_summary }
      end

      summary_list.with_row do |row|
        row.with_key { "Notes" }
        row.with_value { notes }
      end
    end
  end

  def reason_do_not_vaccinate_summary
    I18n.t(
      "patient_session_statuses.unable_to_vaccinate.banner_explanation.#{state}"
    )
  end

  def time_summary
    vaccination_record&.recorded_at
  end

  def do_not_vaccinate_status_contents
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Reason" }
        row.with_value { reason_do_not_vaccinate_summary }
      end

      summary_list.with_row do |row|
        row.with_key { "Date" }
        row.with_value { date_summary }
      end

      summary_list.with_row do |row|
        row.with_key { "Time" }
        row.with_value { last_action_time.to_fs(:time) }
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { @patient_session.session.location.name }
      end

      summary_list.with_row do |row|
        row.with_key { "Nurse" }
        row.with_value { nurse_name_summary }
      end

      if last_action == :vaccination
        summary_list.with_row do |row|
          row.with_key { "Notes" }
          row.with_value { notes }
        end
      end
    end
  end
end
