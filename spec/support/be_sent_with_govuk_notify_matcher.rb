RSpec::Matchers.matcher :be_sent_with_govuk_notify do
  match do |actual|
    return false unless actual.is_a? Mail::Notify::Message

    matched = true
    if @template.present?
      matched = actual.header[:template_id].value == @template
    end

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
