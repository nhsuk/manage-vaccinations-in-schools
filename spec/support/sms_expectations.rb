# frozen_string_literal: true

module SMSExpectations
  def expect_sms_to(phone_number, template_name, nth = :first)
    template_id = GOVUK_NOTIFY_SMS_TEMPLATES[template_name]
    passthrough_id = NotifyTemplateRenderer.for(:sms).passthrough_template_id
    allowed_ids = [template_id, passthrough_id].compact

    sms =
      if nth == :any
        sms_deliveries.find do
          it[:phone_number] == phone_number &&
            (it[:template_id] == template_id || (passthrough_id && it[:template_id] == passthrough_id))
        end
      else
        sms_deliveries.send(nth)
      end

    expect(sms).not_to be_nil
    expect(sms[:phone_number]).to eq(phone_number)
    expect(allowed_ids).to include(sms[:template_id])
    sms
  end

  def sms_deliveries
    perform_enqueued_jobs

    SMSDeliveryJob.deliveries
  end
end
