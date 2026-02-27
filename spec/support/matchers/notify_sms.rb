# frozen_string_literal: true

RSpec::Matchers.define :matching_notify_sms do |phone_number:, template:|
  description do
    desc = "an SMS to #{phone_number} with template :#{template}"
    desc +=
      " containing #{@expected_content_strings.map(&:inspect).join(", ")}" if @expected_content_strings
    desc
  end

  match do |actual|
    next false unless actual.is_a?(Hash)

    renderer = NotifyTemplateRenderer.for(:sms)
    template_id =
      renderer.template_id_for(template) ||
        GOVUK_NOTIFY_SMS_TEMPLATES.fetch(template)

    next false unless actual[:phone_number] == phone_number
    unless [template_id, renderer.passthrough_template_id].include?(
             actual[:template_id]
           )
      next false
    end
    next true if @expected_content_strings.blank?

    personalisation = actual[:personalisation] || {}
    next false unless personalisation.key?(:body)

    content = personalisation[:body]
    @expected_content_strings.all? { |s| content.include?(s) }
  end

  chain(:with_content_including) do |*strings|
    @expected_content_strings = strings
  end

  failure_message do
    base = "expected #{description}"

    if actual.nil?
      "#{base}, but no SMS messages were sent"
    else
      "#{base}, but got SMS to #{actual[:phone_number]} with template_id #{actual[:template_id]}"
    end
  end
end
