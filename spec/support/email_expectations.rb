# frozen_string_literal: true

module EmailExpectations
  def expect_email_to(email_address, template_name, nth = :first)
    template_id = GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template_name)

    email =
      if nth == :any
        email_deliveries.find do
          it[:email_address] == email_address && it[:template_id] == template_id
        end
      else
        email_deliveries.send(nth)
      end

    expect(email).not_to be_nil
    expect(email[:email_address]).to eq(email_address)
    expect(email[:template_id]).to eq(template_id)
  end

  def email_deliveries
    perform_enqueued_jobs(only: EmailDeliveryJob)

    EmailDeliveryJob.deliveries
  end
end
