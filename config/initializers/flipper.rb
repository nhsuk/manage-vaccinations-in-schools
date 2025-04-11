# frozen_string_literal: true

if Rails.env.test?
  require "flipper/adapters/pstore"
  require "flipper"

  Flipper.configure do |config|
    config.default do
      Flipper.new(Flipper::Adapters::PStore.new("tmp/flipper.test.pstore"))
    end
  end
end

DESCRIPTIONS =
  YAML.safe_load(File.read(Rails.root.join("config/feature_flags.yml")))

Flipper::UI.configure do |config|
  config.show_feature_description_in_list = true
  config.descriptions_source = ->(keys) { DESCRIPTIONS.slice(*keys) }

  if Rails.env.production?
    config.banner_text = "This will configure features in production."
    config.banner_class = "danger"
  end
end
