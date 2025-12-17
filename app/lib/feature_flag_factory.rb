# frozen_string_literal: true

class FeatureFlagFactory
  def self.call
    names =
      YAML.safe_load(
        File.read(Rails.root.join("config/feature_flags.yml"))
      ).keys

    names.each { Flipper.add(it) unless Flipper.exist?(it) }

    Flipper.features.each do |feature|
      feature.remove unless feature.name.to_s.in?(names)
    end
  end

  FEATURES_FOR_DEVELOPMENT = %i[
    dev_tools
    import_review_screen
    reporting_api
    testing_api
  ].freeze

  def self.enable_for_development!
    unless Rails.env.development? || Rails.env.end_to_end?
      raise "These flags should only be enabled in development or end_to_end."
    end

    FEATURES_FOR_DEVELOPMENT.each { Flipper.enable(it) }
  end
end
