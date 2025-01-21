# frozen_string_literal: true

RSpec::Matchers.matcher :have_delivered_sms do |template_name = nil|
  supports_block_expectations

  chain :with do |params|
    @params = params
  end

  match do |actual|
    expect { actual.call }.to have_enqueued_job(SMSDeliveryJob).with(
      *[template_name].compact,
      **(@params || {})
    )
  end

  match_when_negated do |actual|
    expect { actual.call }.not_to have_enqueued_job(SMSDeliveryJob).with(
      *[template_name].compact,
      **(@params || {})
    )
  end
end
