# frozen_string_literal: true

class NotifyTemplateRenderer
  class TemplateNotFound < StandardError
  end

  PASSTHROUGH_TEMPLATE_IDS = {
    email: "305a53f8-86eb-485e-85a5-328c9aabba45"
  }.freeze
  TEMPLATE_FRONTMATTER_DELIMITER = "---\n"
  TEMPLATE_BODY_SEPARATOR = "\n---\n"

  def self.for(channel) = new(channel:)

  def initialize(channel:)
    @channel = channel
  end

  def passthrough_template_id = PASSTHROUGH_TEMPLATE_IDS[@channel]

  def passthrough_configured? = passthrough_template_id.present?

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
      frontmatter, = parse_frontmatter(content)
      if frontmatter["template_id"].present?
        return frontmatter["template_id"].to_s
      end
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
        frontmatter, = parse_frontmatter(content)
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

    subject =
      if frontmatter["subject"]
        render_erb(frontmatter["subject"].to_s, context_binding)
      else
        ""
      end
    { subject:, body: }
  rescue NameError => e
    raise NameError,
          "#{e.message} in #{@channel} template '#{template_name}' (#{path})"
  end

  private

  def config_hash
    GOVUK_NOTIFY_EMAIL_TEMPLATES
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
