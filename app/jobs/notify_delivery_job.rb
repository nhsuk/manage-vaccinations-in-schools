# frozen_string_literal: true

class NotifyDeliveryJob < ApplicationJob
  queue_as { Rails.configuration.action_mailer.deliver_later_queue_name }

  def self.client
    @client ||=
      Notifications::Client.new(
        Rails.configuration.action_mailer.notify_settings[:api_key]
      )
  end

  def self.deliveries
    @deliveries ||= []
  end

  def self.send_via_notify?
    Rails.configuration.action_mailer.delivery_method == :notify
  end

  def self.send_via_test?
    Rails.configuration.action_mailer.delivery_method == :test
  end

  class UnknownTemplate < StandardError
  end
end
