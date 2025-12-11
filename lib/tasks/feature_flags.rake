# frozen_string_literal: true

namespace :feature_flags do
  desc "Seeds all the feature flags ensuring they are visible in the UI."
  task seed: :environment do
    FeatureFlagFactory.call
  end

  desc "Enable feature flags most useful for development."
  task enable_for_development: :seed do
    FeatureFlagFactory.enable_for_development!
  end
end
