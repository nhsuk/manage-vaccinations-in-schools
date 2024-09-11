# frozen_string_literal: true

module EmailExpectations
  def expect_email_to(to, template_name, nth = :first)
    email =
      if nth == :any
        sent_emails.find { |e| e.to.include?(to) }
      else
        sent_emails.send(nth)
      end

    expect(email).not_to be_nil

    expect(email.to).to eq([to])

    expect(email.template_id).to eq(GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name])
  end

  def sent_emails
    perform_enqueued_jobs

    ActionMailer::Base.deliveries
  end
end
