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
end
