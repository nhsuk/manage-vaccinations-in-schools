# frozen_string_literal: true

class AppFlashMessageComponent < ViewComponent::Base
  attr_reader :body, :heading, :heading_link_text, :heading_link_href

  def initialize(flash:)
    super

    flash = flash.to_h.with_indifferent_access
    @message_key = (recognised_message_keys & flash.keys.map(&:to_sym)).first

    if flash[@message_key].is_a?(Hash)
      @title = flash[@message_key][:title]
      @heading = flash[@message_key][:heading]
      @heading_link_text = flash[@message_key][:heading_link_text]
      @heading_link_href = flash[@message_key][:heading_link_href]
      @body = flash[@message_key][:body].to_s
    elsif flash[@message_key].is_a?(Array)
      @heading = flash[@message_key].first
      @body = flash[@message_key][1..].join(" ")
    else
      @heading = flash[@message_key]
    end
  end

  def title
    @title ||
      I18n.t(type, scope: :notification_banner, default: type.to_s.humanize)
  end

  def type
    @type ||= devise_message_keys_hash.fetch(@message_key, @message_key)
  end

  def classes
    "govuk-notification-banner--#{type}"
  end

  def role
    %i[warning success].include?(type) ? "alert" : "region"
  end

  def render?
    @heading.present? || @body.present?
  end

  def success?
    type == :success
  end

  private

  def primary_message_keys
    @primary_message_keys ||= %i[info success warning]
  end

  def devise_message_keys_hash
    @devise_message_keys_hash ||= { alert: :warning, notice: :info }
  end

  def recognised_message_keys
    @recognised_message_keys ||=
      primary_message_keys + devise_message_keys_hash.keys
  end
end
