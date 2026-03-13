# frozen_string_literal: true

class NotifyTemplate
  attr_reader :name, :channel, :id

  def self.find(name, channel:)
    name = name.to_sym
    channel = channel.to_sym

    if (template = CommsTemplate.find(name, channel:))
      new(name:, channel:, id: template.id, local: true)
    elsif (id = config_hash(channel)[name])
      new(name:, channel:, id:, local: false)
    end
  end

  def self.find_by_id(template_id, channel:)
    return nil if template_id.blank?

    channel = channel.to_sym

    if (template = CommsTemplate.find_by_id(template_id, channel:))
      new(name: template.name, channel:, id: template_id.to_s, local: true)
    elsif (
          name =
            config_hash(channel).key(template_id) ||
              GOVUK_NOTIFY_UNUSED_TEMPLATES[template_id.to_s]
        )
      new(name:, channel:, id: template_id.to_s, local: false)
    end
  end

  def self.exists?(name, channel:, source: :any)
    channel = channel.to_sym
    case source
    when :local
      CommsTemplate.exists?(name, channel:)
    when :govuk_notify
      config_hash(channel)[name.to_sym].present?
    when :any
      CommsTemplate.exists?(name, channel:) ||
        config_hash(channel)[name.to_sym].present?
    else
      raise ArgumentError, "Unknown source: #{source}"
    end
  end

  def self.all_ids(channel:)
    (config_hash(channel).values + CommsTemplate.all_ids(channel:)).uniq.freeze
  end

  def initialize(name:, channel:, id:, local:)
    @name = name.to_sym
    @channel = channel.to_sym
    @id = id
    @local = local
  end

  def local? = @local

  def render(personalisation)
    CommsTemplate.find(@name, channel: @channel).render(personalisation)
  end

  class << self
    private

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
