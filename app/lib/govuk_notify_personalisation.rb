# frozen_string_literal: true

class GovukNotifyPersonalisation
  include Rails.application.routes.url_helpers

  def initialize(
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    patient_session: nil,
    programme: nil,
    session: nil,
    vaccination_record: nil
  )
    patient_session ||= vaccination_record&.patient_session

    @consent = consent
    @consent_form = consent_form
    @parent = parent || consent&.parent
    @patient = patient || consent&.patient || patient_session&.patient
    @programme =
      programme || vaccination_record&.programme || consent_form&.programme ||
        consent&.programme
    @session = session || consent_form&.session || patient_session&.session
    @team =
      programme&.team || session&.team || patient_session&.team ||
        consent_form&.team || consent&.team || vaccination_record&.team
    @vaccination_record = vaccination_record
  end

  def call
    {
      batch_name:,
      close_consent_date:,
      close_consent_short_date:,
      consent_link:,
      day_month_year_of_vaccination:,
      full_and_preferred_patient_name:,
      location_name:,
      parent_name:,
      programme_name:,
      reason_did_not_vaccinate:,
      reason_for_refusal:,
      session_date:,
      session_short_date:,
      short_patient_name:,
      short_patient_name_apos:,
      show_additional_instructions:,
      survey_deadline_date:,
      team_email:,
      team_name:,
      team_phone:,
      today_or_date_of_vaccination:,
      vaccination:
    }.compact
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :consent,
              :consent_form,
              :parent,
              :patient,
              :programme,
              :session,
              :team,
              :vaccination_record

  def batch_name
    vaccination_record&.batch&.name
  end

  def close_consent_date
    session.close_consent_at.to_fs(:short_day_of_week)
  end

  def close_consent_short_date
    session.close_consent_at.to_fs(:short)
  end

  def consent_link
    host + start_session_parent_interface_consent_forms_path(session)
  end

  def day_month_year_of_vaccination
    vaccination_record&.recorded_at&.to_date&.to_fs(:uk_short)
  end

  def full_and_preferred_patient_name
    patient_or_consent_form = consent_form || patient

    if (common_name = patient_or_consent_form.common_name).present?
      patient_or_consent_form.full_name + " (known as #{common_name})"
    else
      patient_or_consent_form.full_name
    end
  end

  def host
    if Rails.env.development? || Rails.env.test?
      "http://localhost:4000"
    else
      "https://#{Settings.give_or_refuse_consent_host}"
    end
  end

  def location_name
    session.location.name
  end

  def parent_name
    consent_form&.parent_name || parent&.name
  end

  def programme_name
    programme&.name
  end

  def reason_did_not_vaccinate
    return if vaccination_record.nil? || vaccination_record.administered?

    reason = vaccination_record.reason
    I18n.t(
      "mailers.vaccination_mailer.reasons_did_not_vaccinate.#{reason}",
      short_patient_name:
    )
  end

  def reason_for_refusal
    reason = consent_form&.reason || consent&.reason_for_refusal
    return if reason.nil?

    I18n.t("mailers.consent_form_mailer.reasons_for_refusal.#{reason}")
  end

  def session_date
    session.date.to_fs(:short_day_of_week)
  end

  def session_short_date
    session.date.to_fs(:short)
  end

  def short_patient_name
    [
      consent_form&.common_name,
      consent_form&.first_name,
      patient&.common_name,
      patient&.first_name
    ].compact_blank.first
  end

  def short_patient_name_apos
    apos = "’"
    apos += "s" unless short_patient_name.ends_with?("s")
    short_patient_name + apos
  end

  def show_additional_instructions
    return if vaccination_record.nil?

    vaccination_record.already_had? ? "no" : "yes"
  end

  def survey_deadline_date
    recorded_at = consent_form&.recorded_at || consent&.recorded_at
    return if recorded_at.nil?

    (recorded_at + 7.days).to_date.to_fs(:long)
  end

  def team_email
    team.email
  end

  def team_name
    team.name
  end

  def team_phone
    team.phone
  end

  def today_or_date_of_vaccination
    return if vaccination_record.nil?

    if vaccination_record.recorded_at.today?
      "today"
    else
      vaccination_record.recorded_at.to_date.to_fs(:long)
    end
  end

  def vaccination
    "#{programme_name} vaccination"
  end
end
