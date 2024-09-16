# frozen_string_literal: true

RSpec::Matchers.matcher :have_enqueued_text do |template_name = nil|
  supports_block_expectations

  chain :with do |params|
    @params = params
  end

  match do |actual|
    expect { actual.call }.to have_enqueued_job(TextDeliveryJob).with(
      *[template_name].compact,
      **(@params || {})
    )
  end

  match_when_negated do |actual|
    expect { actual.call }.not_to have_enqueued_job(TextDeliveryJob).with(
      *[template_name].compact,
      **(@params || {})
    )
  end
end
