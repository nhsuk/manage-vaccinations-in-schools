# frozen_string_literal: true

path = Rails.root.join("public/ref")

version = File.read(path).strip if File.exist?(path)
APP_VERSION = version.presence
