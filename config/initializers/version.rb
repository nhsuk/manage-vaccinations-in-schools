# frozen_string_literal: true

version = ENV["APP_VERSION"]
if Rails.env.production? && version.present? &&
     !version.match?(/\Av\d+(\.\d+)+\z/)
  version = nil
end

APP_VERSION = version.presence
