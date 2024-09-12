# frozen_string_literal: true

class ApplicationMailer < Mail::Notify::Mailer
  private

  def app_template_mail(template_name, *opts_args, **opts_kwargs)
    template_mail(
      GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template_name),
      **opts(*opts_args, **opts_kwargs)
    )
  end

  def opts(session, patient, parent)
    @session = session
    @patient = patient
    @parent = parent

    { to:, reply_to_id:, personalisation: }
  end

  def to
    @parent.is_a?(ConsentForm) ? @parent.parent_email : @parent.email
  end

  def reply_to_id
    @session.programme.team.reply_to_id
  end

  def personalisation
    {
      full_and_preferred_patient_name:,
      location_name:,
      long_date:,
      parent_name:,
      short_date:,
      short_patient_name:,
      short_patient_name_apos:,
      team_email:,
      team_name:,
      team_phone:,
      vaccination:
    }
  end

  def full_and_preferred_patient_name
    if @patient.common_name.present?
      @patient.full_name + " (known as #{@patient.common_name})"
    else
      @patient.full_name
    end
  end

  def short_patient_name
    @patient.common_name.presence || @patient.first_name
  end

  def short_patient_name_apos
    apos = "'"
    apos += "s" unless short_patient_name.ends_with?("s")
    short_patient_name + apos
  end

  def parent_name
    @parent.is_a?(ConsentForm) ? @parent.parent_name : @parent.name
  end

  def location_name
    @session.location.name
  end

  def short_date
    @session.date.to_fs(:short)
  end

  def long_date
    @session.date.to_fs(:short_day_of_week)
  end

  def team_email
    @session.programme.team.email
  end

  def team_name
    @session.programme.team.name
  end

  def team_phone
    @session.programme.team.phone
  end

  def vaccination
    "#{@session.programme.name} vaccination"
  end
end
