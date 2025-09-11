# frozen_string_literal: true

class EnableNewFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    Flipper.enable(:imms_api_integration)
    Flipper.enable(:imms_api_sync_job)
  end
end
