# frozen_string_literal: true

namespace :feature_flags do
  desc "Seeds all the feature flags ensuring they are visible in the UI."
  task seed: :environment do
    FeatureFlagFactory.call
  end
end
