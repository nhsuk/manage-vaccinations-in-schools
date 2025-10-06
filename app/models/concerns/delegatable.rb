# frozen_string_literal: true

module Delegatable
  extend ActiveSupport::Concern

  def supports_delegation? = programmes.any?(&:supports_delegation?)

  def pgd_supply_enabled? = supports_delegation? && !psd_enabled?
end
