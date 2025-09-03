# frozen_string_literal: true

require "notifications/client"

class NotifyDeliveryJob < ApplicationJob
  self.queue_adapter = :sidekiq unless Rails.env.test?

  queue_as :notifications

  retry_on Notifications::Client::ServerError, wait: :polynomially_longer

  def self.client
    @client ||=
      Notifications::Client.new(
        Settings.govuk_notify["#{Settings.govuk_notify.mode}_key"]
      )
  end

  def self.deliveries
    @deliveries ||= []
  end

  def self.send_via_notify?
    Settings.govuk_notify&.enabled
  end

  def self.send_via_test?
    Rails.env.test?
  end

  class UnknownTemplate < StandardError
  end
end
