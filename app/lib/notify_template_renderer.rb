# frozen_string_literal: true

class NotifyTemplateRenderer
  class TemplateNotFound < StandardError
  end

  TEMPLATE_FRONTMATTER_DELIMITER = "---\n"
  TEMPLATE_BODY_SEPARATOR = "\n---\n"

  def self.for(channel) = new(channel:)

  def initialize(channel:)
    @channel = channel
  end

  def render(template_name, personalisation)
    path = template_path(template_name)
    raise TemplateNotFound, "No template at #{path}" unless path.exist?

    content = File.read(path)
    frontmatter, body_content = parse_frontmatter(content)
    context_binding = personalisation.instance_eval { binding }

    body = render_erb(body_content, context_binding)

    if @channel == :sms
      # sanitise smart quotes in the body
      # to avoid potential encoding switch to UCS-2
      # and dropping the character limit per SMS to 70 characters
      # https://www.notifications.service.gov.uk/pricing/text-messages
      { body: SmartQuoteSanitiser.call(body) }
    else
      subject =
        if frontmatter["subject"]
          render_erb(frontmatter["subject"].to_s, context_binding)
        else
          ""
        end
      { subject:, body: }
    end
  rescue NameError => e
    raise NameError,
          "#{e.message} in #{@channel} template '#{template_name}' (#{path})"
  end

  private

  def template_path(template_name)
    Rails.root.join(
      "app/views/notify_templates",
      @channel.to_s,
      "#{template_name}.text.erb"
    )
  end

  def parse_frontmatter(content)
    unless content.start_with?(TEMPLATE_FRONTMATTER_DELIMITER)
      return {}, content
    end

    frontmatter_block, body_content = content.split(TEMPLATE_BODY_SEPARATOR, 2)
    return {}, content if body_content.nil?

    frontmatter_str =
      frontmatter_block.delete_prefix(TEMPLATE_FRONTMATTER_DELIMITER)
    frontmatter = YAML.safe_load(frontmatter_str) || {}

    [frontmatter, body_content]
  end

  def render_erb(template_string, context_binding)
    ERB.new(template_string, trim_mode: nil).result(context_binding)
  end
end
