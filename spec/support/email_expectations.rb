# frozen_string_literal: true

module EmailExpectations
  # Returns the sent content (subject + body for passthrough emails, or personalisation values) for assertions.
  def sent_email_content(email)
    return "" unless email && email[:personalisation]

    p = email[:personalisation]
    if p.key?(:body)
      [p[:subject], p[:body]].compact.map(&:to_s).join("\n")
    else
      p.values.map(&:to_s).join(" ")
    end
  end

  def expect_email_to(email_address, template_name, nth = :first)
    email_renderer = NotifyTemplateRenderer.for(:email)
    template_id =
      email_renderer.template_id_for(template_name) ||
      GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template_name)
    passthrough_id = email_renderer.passthrough_template_id

    email =
      if nth == :any
        email_deliveries.find do
          it[:email_address] == email_address &&
            (it[:template_id] == template_id || it[:template_id] == passthrough_id)
        end
      else
        email_deliveries.send(nth)
      end

    expect(email).not_to be_nil
    expect(email[:email_address]).to eq(email_address)
    expect([template_id, passthrough_id]).to include(email[:template_id])
    DeliveredEmail.new(email, self)
  end

  def email_deliveries
    perform_enqueued_jobs(only: EmailDeliveryJob)

    EmailDeliveryJob.deliveries
  end

  # Wrapper returned by expect_email_to so you can chain content assertions.
  class DeliveredEmail
    def initialize(email, context)
      @email = email
      @context = context
    end

    def [](key)
      @email[key]
    end

    def with_content_including(*strings)
      return self unless @email[:personalisation]&.key?(:body)

      content = @context.sent_email_content(@email)
      strings.each { |s| expect(content).to include(s) }
      self
    end
  end
end
