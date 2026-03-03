# frozen_string_literal: true

RSpec::Matchers.define :matching_notify_email do |to:, template:|
  description do
    desc = "an email to #{to} with template :#{template}"
    desc +=
      " containing #{@expected_content_strings.map(&:inspect).join(", ")}" if @expected_content_strings
    desc
  end

  match do |actual|
    next false unless actual.is_a?(Hash)

    renderer = NotifyTemplateRenderer.for(:email)
    template_id =
      renderer.template_id_for(template) ||
        GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template)

    next false unless actual[:email_address] == to
    unless [template_id, renderer.passthrough_template_id].include?(
             actual[:template_id]
           )
      next false
    end
    next true if @expected_content_strings.blank?

    personalisation = actual[:personalisation] || {}
    next false unless personalisation.key?(:body)

    content = [personalisation[:subject], personalisation[:body]].compact.join(
      "\n"
    )
    @expected_content_strings.all? { |s| content.include?(s) }
  end

  chain(:with_content_including) do |*strings|
    @expected_content_strings = strings
  end

  failure_message do
    base = "expected #{description}"

    if actual.nil?
      "#{base}, but no emails were sent"
    else
      "#{base}, but got email to #{actual[:email_address]} with template_id #{actual[:template_id]}"
    end
  end
end
