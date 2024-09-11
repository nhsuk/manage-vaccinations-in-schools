# frozen_string_literal: true

RSpec::Matchers.matcher :be_sent_with_govuk_notify do
  match do |actual|
    unless actual.is_a?(Mail::Notify::Message) ||
             actual.is_a?(ActionMailer::MessageDelivery)
      return false
    end

    template_matches =
      @template.nil? || actual.template_id == @template ||
        actual.template_id == GOVUK_NOTIFY_EMAIL_TEMPLATES[@template.to_sym]

    to_matches = @to_email.nil? || actual.to == [@to_email]

    template_matches && to_matches
  end

  chain :using_template do |template|
    @template = template.to_s
  end

  chain :to do |email|
    @to_email = email
  end
end
