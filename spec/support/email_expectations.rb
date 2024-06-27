# frozen_string_literal: true

module EmailExpectations
  def expect_email_to(to, template, nth = :first)
    email =
      if nth == :any
        sent_emails.find { |e| e.to.include?(to) }
      else
        sent_emails.send(nth)
      end
    expect(email).not_to be_nil
    expect(email).to be_sent_with_govuk_notify.using_template(template).to(to)
  end

  def sent_emails
    perform_enqueued_jobs

    ActionMailer::Base.deliveries
  end
end
