# frozen_string_literal: true

namespace :feature_flags do
  desc "Seeds all the feature flags ensuring they are visible in the UI."
  task seed: :environment do
    FeatureFlagFactory.call
  end

  desc "Activates development feature toggles for testing environment."
  task activate_dev_toggles: :environment do
    Flipper.enable(:dev_tools)
    Flipper.enable(:testing_api)
    Flipper.enable(:import_review_screen)
    Flipper.enable(:programme_status)
  end
end
