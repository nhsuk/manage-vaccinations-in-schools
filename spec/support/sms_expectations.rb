# frozen_string_literal: true

module SMSExpectations
  def expect_sms_to(phone_number, template_name, nth = :first)
    template_id = GOVUK_NOTIFY_SMS_TEMPLATES[template_name]

    sms =
      if nth == :any
        sms_deliveries.find do
          it[:phone_number] == phone_number && it[:template_id] == template_id
        end
      else
        sms_deliveries.send(nth)
      end

    expect(sms).not_to be_nil
    expect(sms[:phone_number]).to eq(phone_number)
    expect(sms[:template_id]).to eq(template_id)
  end

  def sms_deliveries
    perform_enqueued_jobs

    SMSDeliveryJob.deliveries
  end
end
