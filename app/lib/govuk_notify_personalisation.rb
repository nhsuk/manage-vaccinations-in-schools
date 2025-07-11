# frozen_string_literal: true

class GovukNotifyPersonalisation
  include Rails.application.routes.url_helpers

  include PhoneHelper
  include VaccinationRecordsHelper

  def initialize(
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    programmes: nil,
    session: nil,
    vaccination_record: nil
  )
    @consent = consent
    @consent_form = consent_form
    @parent = parent || consent&.parent
    @patient = patient || consent&.patient || vaccination_record&.patient
    @programmes =
      programmes.presence || consent_form&.programmes.presence ||
        [consent&.programme || vaccination_record&.programme].compact
    @session =
      session || consent_form&.actual_session ||
        consent_form&.original_session || vaccination_record&.session
    @organisation =
      session&.organisation || consent_form&.organisation ||
        consent&.organisation || vaccination_record&.organisation
    @team = session&.team || consent_form&.team || vaccination_record&.team
    @vaccination_record = vaccination_record
  end

  def to_h
    {
      batch_name:,
      can_self_consent:,
      catch_up:,
      consent_deadline:,
      consent_link:,
      consented_vaccine_methods_message:,
      day_month_year_of_vaccination:,
      full_and_preferred_patient_name:,
      has_multiple_dates:,
      location_name:,
      next_or_today_session_date:,
      next_or_today_session_dates:,
      next_or_today_session_dates_or:,
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
      vaccination:,
      vaccine_brand:,
      vaccine_is_injection:,
      vaccine_is_nasal:,
      vaccine_side_effects:
    }.compact
  end

  attr_reader :consent,
              :consent_form,
              :parent,
              :patient,
              :programmes,
              :session,
              :team,
              :organisation,
              :vaccination_record

  private

  def batch_name
    vaccination_record&.batch&.name
  end

  def can_self_consent
    return nil if patient.nil?
    patient.year_group >= 7 ? "yes" : "no"
  end

  def catch_up
    return nil if patient.nil? || programmes.empty?
    if patient.year_group == programmes.flat_map(&:year_groups).sort.uniq.first
      "no"
    else
      "yes"
    end
  end

  def not_catch_up
    return nil if patient.nil? || programmes.empty?
    if patient.year_group == programmes.flat_map(&:year_groups).sort.uniq.first
      "yes"
    else
      "no"
    end
  end

  def consent_deadline
    next_date = session.future_dates.first

    close_consent_at =
      next_date ? (next_date - 1.day) : session.close_consent_at

    close_consent_at&.to_fs(:short_day_of_week)
  end

  def consent_link
    return nil if session.nil? || programmes.empty?
    host +
      start_parent_interface_consent_forms_path(
        session,
        programmes.map(&:to_param).join("-")
      )
  end

  def consented_vaccine_methods_message
    return if consent_form.nil? || consent_form.programmes.none?(&:flu?)

    consent_form_programmes = consent_form.consent_form_programmes

    consented_vaccine_methods =
      if consent_form_programmes.any?(&:vaccine_method_injection_and_nasal?)
        "nasal spray flu vaccine, or the injected flu vaccine if the nasal spray is not suitable"
      elsif consent_form_programmes.any?(&:vaccine_method_nasal?)
        "nasal spray flu vaccine"
      else
        "injected flu vaccine"
      end

    "You’ve agreed that #{short_patient_name} can have the #{consented_vaccine_methods}."
  end

  def day_month_year_of_vaccination
    vaccination_record&.performed_at&.to_date&.to_fs(:uk_short)
  end

  def full_and_preferred_patient_name
    (consent_form || patient).full_name_with_known_as(context: :parents)
  end

  def has_multiple_dates
    return nil if session.nil?

    if session.today_or_future_dates.length > 1
      "yes"
    else
      "no"
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
    if vaccination_record
      vaccination_record_location(vaccination_record)
    else
      session.location.name
    end
  end

  def next_or_today_session_date
    session.next_date(include_today: true)&.to_fs(:short_day_of_week)
  end

  def next_or_today_session_dates
    session
      .today_or_future_dates
      .map { it.to_fs(:short_day_of_week) }
      .to_sentence
  end

  def next_or_today_session_dates_or
    session
      .today_or_future_dates
      .map { it.to_fs(:short_day_of_week) }
      .to_sentence(last_word_connector: ", or ", two_words_connector: " or ")
  end

  def next_session_date
    session.next_date(include_today: false)&.to_fs(:short_day_of_week)
  end

  def next_session_dates
    session.future_dates.map { it.to_fs(:short_day_of_week) }.to_sentence
  end

  def next_session_dates_or
    session
      .future_dates
      .map { it.to_fs(:short_day_of_week) }
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
    programmes.map(&:name).to_sentence
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
    dates = session.future_dates.drop(1)
    return "" if dates.empty?

    "If they’re not seen, they’ll be offered the vaccination on #{
      dates.map { it.to_fs(:short_day_of_week) }.to_sentence
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
    format_phone_with_instructions(team || organisation)
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
    [
      programme_name,
      programmes.count == 1 ? "vaccination" : "vaccinations"
    ].join(" ")
  end

  def vaccine_brand
    vaccination_record&.vaccine&.brand
  end

  def vaccine_is_injection = vaccine_is?("injection")

  def vaccine_is_nasal = vaccine_is?("nasal")

  def vaccine_is?(method)
    if vaccination_record
      vaccination_record.vaccine&.method == method ? "yes" : "no"
    elsif programmes.present?
      any_vaccines_with_method =
        if patient
          programmes.any? do |programme|
            # We pick the first method as it's the one most likely to be used
            # to vaccinate the patient. For example, in the case of Flu, the
            # parents will approve nasal (and then optionally injection).
            patient.approved_vaccine_methods(programme:).first == method
          end
        else
          Vaccine.where(programme: programmes, method:).exists?
        end

      any_vaccines_with_method ? "yes" : "no"
    end
  end

  def vaccine_side_effects
    side_effects =
      if vaccination_record
        vaccination_record.vaccine&.side_effects
      elsif programmes.present?
        if patient
          programmes.flat_map do |programme|
            # We pick the first method as it's the one most likely to be used
            # to vaccinate the patient. For example, in the case of Flu, the
            # parents will approve nasal (and then optionally injection).
            method = patient.approved_vaccine_methods(programme:).first
            Vaccine.where(programme:, method:).flat_map(&:side_effects)
          end
        else
          Vaccine.where(programme: programmes).flat_map(&:side_effects)
        end
      end

    return if side_effects.nil?

    descriptions =
      side_effects.map { Vaccine.human_enum_name(:side_effect, it) }.sort.uniq

    descriptions.map { "- #{it}" }.join("\n")
  end
end
