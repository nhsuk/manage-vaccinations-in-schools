# frozen_string_literal: true

module EmailExpectations
  def expect_email_to(to, template_name, nth = :first)
    template_id = GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template_name)

    email =
      if nth == :any
        sent_emails.find do |e|
          e.to.include?(to) && e.template_id == template_id
        end
      else
        sent_emails.send(nth)
      end

    expect(email).not_to be_nil
    expect(email.to).to eq([to])
    expect(email.template_id).to eq(template_id)
  end

  def sent_emails
    perform_enqueued_jobs

    ActionMailer::Base.deliveries
  end
end
