# frozen_string_literal: true

module TextExpectations
  def expect_text_to(phone_number, template_name, nth = :first)
    template_id = GOVUK_NOTIFY_TEXT_TEMPLATES[template_name]

    text =
      if nth == :any
        sent_texts.find do |t|
          t[:phone_number] == phone_number && t[:template_id] == template_id
        end
      else
        sent_texts.send(nth)
      end

    expect(text).not_to be_nil
    expect(text[:phone_number]).to eq(phone_number)
    expect(text[:template_id]).to eq(template_id)
  end

  def sent_texts
    perform_enqueued_jobs

    TextDeliveryJob.deliveries
  end
end
