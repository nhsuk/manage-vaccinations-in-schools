# frozen_string_literal: true

class NotifyTemplate
  PASSTHROUGH_TEMPLATE_IDS = {
    email: "305a53f8-86eb-485e-85a5-328c9aabba45",
    sms: "c242b359-73d6-4b74-bda2-136093550636"
  }.freeze

  attr_reader :name, :channel, :id

  def self.find(name, channel:)
    name = name.to_sym
    channel = channel.to_sym
    id = template_id_for(name, channel)
    return nil unless id

    new(name:, channel:, id:, local: template_path(name, channel).exist?)
  end

  def self.find_by_id(template_id, channel:)
    return nil if template_id.blank?

    channel = channel.to_sym
    name =
      template_name_for(template_id, channel) ||
        GOVUK_NOTIFY_UNUSED_TEMPLATES[template_id.to_s]
    return nil unless name

    new(
      name:,
      channel:,
      id: template_id.to_s,
      local: template_path(name, channel).exist?
    )
  end

  def self.exists?(name, channel:, source: :any)
    channel = channel.to_sym
    path = template_path(name, channel)
    case source
    when :local
      path.exist?
    when :govuk_notify
      config_hash(channel)[name.to_sym].present?
    when :any
      path.exist? || config_hash(channel)[name.to_sym].present?
    else
      raise ArgumentError, "Unknown source: #{source}"
    end
  end

  def initialize(name:, channel:, id:, local:)
    @name = name.to_sym
    @channel = channel.to_sym
    @id = id
    @local = local
  end
  def local? = @local
  def passthrough_id = PASSTHROUGH_TEMPLATE_IDS[@channel]
  def delivery_id = local? ? passthrough_id : id

  def render(personalisation)
    NotifyTemplateRenderer.for(@channel).render(@name, personalisation)
  end

  class << self
    private

    def template_id_for(name, channel)
      path = template_path(name, channel)
      if path.exist?
        content = File.read(path)
        frontmatter, = parse_frontmatter(content)
        if frontmatter["template_id"].present?
          return frontmatter["template_id"].to_s
        end
      end
      config_hash(channel)[name.to_sym]
    end

    def template_name_for(template_id, channel)
      dir = Rails.root.join("app/views/notify_templates", channel.to_s)
      if Dir.exist?(dir)
        Dir.each_child(dir) do |filename|
          next unless filename.end_with?(".text.erb")

          name = filename.delete_suffix(".text.erb").to_sym
          content = File.read(File.join(dir, filename))
          frontmatter, = parse_frontmatter(content)
          return name if frontmatter["template_id"].to_s == template_id.to_s
        end
      end
      config_hash(channel).key(template_id)
    end

    def template_path(name, channel)
      Rails.root.join(
        "app/views/notify_templates",
        channel.to_s,
        "#{name}.text.erb"
      )
    end

    def parse_frontmatter(content)
      delimiter = "---\n"
      separator = "\n---\n"
      return {}, content unless content.start_with?(delimiter)

      frontmatter_block, body_content = content.split(separator, 2)
      return {}, content if body_content.nil?

      frontmatter_str = frontmatter_block.delete_prefix(delimiter)
      frontmatter = YAML.safe_load(frontmatter_str) || {}
      [frontmatter, body_content]
    end

    def config_hash(channel)
      case channel
      when :sms
        GOVUK_NOTIFY_SMS_TEMPLATES
      else
        GOVUK_NOTIFY_EMAIL_TEMPLATES
      end
    end
  end
end
