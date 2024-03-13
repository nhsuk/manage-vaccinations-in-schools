module FeedbackMailerConcern
  extend ActiveSupport::Concern

  def send_feedback_request_mail(consent_form:)
    if consent_form.feedback_request_sent_at.blank?
      FeedbackMailer.give_feedback(consent_form:).deliver_later(wait: 1.hour)
      consent_form.update!(feedback_request_sent_at: Time.zone.now)
    end
  end
end
