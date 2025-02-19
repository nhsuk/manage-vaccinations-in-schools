# frozen_string_literal: true

class GovukNotifyPersonalisation
  include Rails.application.routes.url_helpers

  def initialize(
    consent: nil,
    consent_form: nil,
    patient: nil,
    programme: nil,
    session: nil,
    vaccination_record: nil
  )
    @consent = consent
    @consent_form = consent_form
    @patient = patient || consent&.patient || vaccination_record&.patient
    @programme =
      programme || vaccination_record&.programme || consent_form&.programme ||
        consent&.programme
    @session =
      session || consent_form&.actual_upcoming_session ||
        consent_form&.original_session || vaccination_record&.session
    @organisation =
      session&.organisation || consent_form&.organisation ||
        consent&.organisation || vaccination_record&.organisation
    @team = session&.team || consent_form&.team || vaccination_record&.team
    @vaccination_record = vaccination_record
  end

  def call
    {
      batch_name:,
      catch_up:,
      consent_deadline:,
      consent_link:,
      day_month_year_of_vaccination:,
      full_and_preferred_patient_name:,
      location_name:,
      next_session_date:,
      next_session_dates:,
      next_session_dates_or:,
      not_catch_up:,
      organisation_privacy_notice_url:,
      organisation_privacy_policy_url:,
      outcome_administered:,
      outcome_not_administered:,
      patient_date_of_birth:,
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
              :patient,
              :programme,
              :session,
              :team,
              :organisation,
              :vaccination_record

  def batch_name
    vaccination_record&.batch&.name
  end

  def catch_up
    return nil if patient.nil? || programme.nil?
    patient.year_group == programme.year_groups.first ? "no" : "yes"
  end

  def not_catch_up
    return nil if patient.nil? || programme.nil?
    patient.year_group == programme.year_groups.first ? "yes" : "no"
  end

  def consent_deadline
    next_date = session.future_dates.first

    close_consent_at =
      next_date ? (next_date - 1.day) : session.close_consent_at

    close_consent_at&.to_fs(:short_day_of_week)
  end

  def consent_link
    return nil if session.nil? || programme.nil?
    host + start_parent_interface_consent_forms_path(session, programme)
  end

  def day_month_year_of_vaccination
    vaccination_record&.performed_at&.to_date&.to_fs(:uk_short)
  end

  def full_and_preferred_patient_name
    patient_or_consent_form = consent_form || patient

    if patient_or_consent_form.has_preferred_name?
      patient_or_consent_form.full_name(context: :parents) +
        " (known as #{patient_or_consent_form.preferred_full_name(context: :parents)})"
    else
      patient_or_consent_form.full_name(context: :parents)
    end
  end

  def host
    if Rails.env.local?
      "http://localhost:4000"
    else
      "https://#{Settings.give_or_refuse_consent_host}"
    end
  end

  def location_name
    session.location.name
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

  def organisation_privacy_notice_url
    organisation.privacy_notice_url
  end

  def organisation_privacy_policy_url
    organisation.privacy_policy_url
  end

  def outcome_administered
    return if vaccination_record.nil?
    vaccination_record.administered? ? "yes" : "no"
  end

  def outcome_not_administered
    return if vaccination_record.nil?
    vaccination_record.not_administered? ? "yes" : "no"
  end

  def patient_date_of_birth
    patient&.date_of_birth&.to_fs(:long)
  end

  def programme_name
    programme&.name
  end

  def reason_did_not_vaccinate
    return if vaccination_record.nil? || vaccination_record.administered?

    I18n.t(
      vaccination_record.outcome,
      scope: "mailers.vaccination_mailer.reasons_did_not_vaccinate",
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
      consent_form&.preferred_given_name,
      consent_form&.given_name,
      patient&.preferred_given_name,
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
    return "" if dates.empty?

    "If they’re not seen, they’ll be offered the vaccination on #{
      dates.map { _1.to_fs(:short_day_of_week) }.to_sentence
    }."
  end

  def survey_deadline_date
    recorded_at = consent_form&.recorded_at || consent&.created_at
    return if recorded_at.nil?

    (recorded_at + 7.days).to_date.to_fs(:long)
  end

  def team_email
    (team || organisation).email
  end

  def team_name
    (team || organisation).name
  end

  def team_phone
    (team || organisation).phone
  end

  def today_or_date_of_vaccination
    return if vaccination_record.nil?

    if vaccination_record.performed_at.today?
      "today"
    else
      vaccination_record.performed_at.to_date.to_fs(:long)
    end
  end

  def vaccination
    "#{programme_name} vaccination"
  end
end
