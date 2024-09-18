# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ManageVaccinations
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[tasks])

    # DB_SECRET is a JSON string containing the database credentials on AWS.
    # We need to parse it in order to set the DATABASE_URL variable.
    if ENV["DB_SECRET"].present?
      db_config = JSON.parse(ENV["DB_SECRET"])
      username = db_config["username"]
      password = db_config["password"]
      host = db_config["host"]
      port = db_config["port"]
      dbname = db_config["dbname"]
      ENV[
        "DATABASE_URL"
      ] = "postgres://#{username}:#{password}@#{host}:#{port}/#{dbname}"
    end

    config.middleware.use Rack::Deflater

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=2147483648, immutable"
    }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.time_zone = "London"

    config.assets.paths << Rails.root.join(
      "node_modules/govuk-frontend/dist/govuk/assets"
    )

    config.exceptions_app = routes

    config.active_job.queue_adapter = :good_job
    config.good_job.execution_mode = :async

    config.view_component.default_preview_layout = "component_preview"
    config.view_component.preview_controller = "ComponentPreviewsController"
    config.view_component.preview_paths << Rails.root.join(
      "spec/components/previews"
    )
  end
end
