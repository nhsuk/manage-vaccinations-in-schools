# frozen_string_literal: true

require "notifications/client"

class NotifyDeliveryJob < ApplicationJob
  def self.client
    @client ||=
      Notifications::Client.new(
        Settings.govuk_notify["#{Settings.govuk_notify.mode}_key"]
      )
  end

  def self.deliveries
    @deliveries ||= []
  end

  def self.send_via_notify? = Settings.govuk_notify&.enabled

  def self.send_via_test? = Rails.env.test?

  class UnknownTemplate < StandardError
  end
end
