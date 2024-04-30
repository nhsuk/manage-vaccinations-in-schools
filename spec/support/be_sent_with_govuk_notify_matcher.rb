RSpec::Matchers.matcher :be_sent_with_govuk_notify do
  match do |actual|
    unless actual.is_a?(Mail::Notify::Message) ||
             actual.is_a?(ActionMailer::MessageDelivery)
      return false
    end

    matched = true
    matched = actual.template_id == @template if @template.present?

    matched = actual.to == [@to_email] if @to_email.present?

    matched
  end

  chain :using_template do |template|
    @template = template.to_s
  end

  chain :to do |email|
    @to_email = email
  end
end
