# frozen_string_literal: true

class NotifyTemplateRenderer
  class TemplateNotFound < StandardError; end

  # Passthrough template: create in GOV.UK Notify with subject ((subject)), body ((body)).
  # Replace with the real template UUID from the Notify dashboard when ready.
  PASSTHROUGH_EMAIL_TEMPLATE_ID = "REPLACE_WITH_PASSTHROUGH_EMAIL_TEMPLATE_UUID"

  def self.for(channel)
    new(channel: channel)
  end

  def initialize(channel:)
    @channel = channel
  end

  def passthrough_template_id
    case @channel
    when :email then self.class::PASSTHROUGH_EMAIL_TEMPLATE_ID
    when :sms then nil
    else nil
    end
  end

  def passthrough_configured?
    id = passthrough_template_id
    id.present? && !id.to_s.start_with?("REPLACE_")
  end

  def template_path(template_name)
    Rails.root.join(
      "app/views/notify_templates",
      @channel.to_s,
      "#{template_name}.text.erb"
    )
  end

  def template_exists?(template_name)
    template_path(template_name).exist?
  end

  # Resolve template UUID: from frontmatter when local file exists, else from config hash.
  def template_id_for(template_name)
    path = template_path(template_name)
    if path.exist?
      content = File.read(path)
      frontmatter, _ = parse_frontmatter(content)
      return frontmatter["template_id"].to_s if frontmatter["template_id"].present?
    end
    config_hash[template_name.to_sym]
  end

  # Reverse lookup: template_id -> template name. Checks local frontmatter then config hash.
  def template_name_for(template_id)
    return nil if template_id.blank?

    dir = Rails.root.join("app/views/notify_templates", @channel.to_s)
    if Dir.exist?(dir)
      Dir.each_child(dir) do |filename|
        next unless filename.end_with?(".text.erb")

        name = filename.delete_suffix(".text.erb").to_sym
        content = File.read(File.join(dir, filename))
        frontmatter, _ = parse_frontmatter(content)
        return name if frontmatter["template_id"].to_s == template_id.to_s
      end
    end
    config_hash.key(template_id)
  end

  def render(template_name, personalisation)
    path = template_path(template_name)
    raise TemplateNotFound, "No template at #{path}" unless path.exist?

    content = File.read(path)
    frontmatter, body_content = parse_frontmatter(content)
    context_binding = personalisation.instance_eval { binding }

    body = render_erb(body_content, context_binding)

    if @channel == :email
      subject =
        if frontmatter["subject"]
          render_erb(frontmatter["subject"].to_s, context_binding)
        else
          ""
        end
      { subject:, body: }
    else
      { body: }
    end
  end

  private

  def config_hash
    @channel == :email ? GOVUK_NOTIFY_EMAIL_TEMPLATES : GOVUK_NOTIFY_SMS_TEMPLATES
  end

  def parse_frontmatter(content)
    if content.start_with?("---\n")
      parts = content.split("\n---\n", 2)
      return [{}, content] if parts.length < 2

      frontmatter_str = parts[0].delete_prefix("---\n")
      body_content = parts[1]
      frontmatter = YAML.safe_load(frontmatter_str) || {}
      [frontmatter, body_content]
    else
      [{}, content]
    end
  end

  def render_erb(template_string, context_binding)
    ERB.new(template_string, trim_mode: nil).result(context_binding)
  end
end
