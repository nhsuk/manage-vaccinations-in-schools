class SessionMailer < ApplicationMailer
  def session_reminder(session:, patient:)
    template_mail(
      "79e131b2-7816-46d0-9c74-ae14956dd77d",
      **opts(session, patient)
    )
  end

  private

  def opts(session, patient)
    @session = session
    @patient = patient

    { to:, reply_to_id:, personalisation: }
  end
end
