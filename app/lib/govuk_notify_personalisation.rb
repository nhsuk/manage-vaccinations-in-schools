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
    @session =
      session || consent_form&.scheduled_session || patient_session&.session
    @team =
      session&.team || patient_session&.team || consent_form&.team ||
        consent&.team || vaccination_record&.team
    @vaccination_record = vaccination_record
  end

  def call
    {
      batch_name:,
      consent_deadline:,
      consent_link:,
      day_month_year_of_vaccination:,
      full_and_preferred_patient_name:,
      location_name:,
      next_session_date:,
      next_session_dates:,
      next_session_dates_or:,
      parent_full_name:,
      programme_name:,
      reason_did_not_vaccinate:,
      reason_for_refusal:,
      short_patient_name:,
      short_patient_name_apos:,
      show_additional_instructions:,
      subsequent_session_dates_offered_message:,
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

  def consent_deadline
    next_date = session.today_or_future_dates.first
    return nil if next_date.nil?

    (next_date - 1.day).to_fs(:short_day_of_week)
  end

  def consent_link
    return nil if session.nil? || programme.nil?
    host + start_parent_interface_consent_forms_path(session, programme)
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
    session.location&.name
  end

  def next_session_date
    session.today_or_future_dates.first&.to_fs(:short_day_of_week)
  end

  def next_session_dates
    session
      .today_or_future_dates
      .map { _1.to_fs(:short_day_of_week) }
      .to_sentence
  end

  def next_session_dates_or
    session
      .today_or_future_dates
      .map { _1.to_fs(:short_day_of_week) }
      .to_sentence(last_word_connector: ", or ", two_words_connector: " or ")
  end

  def parent_full_name
    consent_form&.parent_full_name || parent&.full_name
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

  def short_patient_name
    [
      consent_form&.common_name,
      consent_form&.given_name,
      patient&.common_name,
      patient&.given_name
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

  def subsequent_session_dates_offered_message
    dates = session.today_or_future_dates.drop(1)
    return if dates.empty?

    "If they’re not seen, they’ll be offered the vaccination on #{
      dates.map { _1.to_fs(:short_day_of_week) }.to_sentence
    }."
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
