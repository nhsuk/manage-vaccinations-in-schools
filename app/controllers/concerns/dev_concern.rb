# frozen_string_literal: true

module DevConcern
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!
    skip_before_action :store_user_location!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    before_action :ensure_dev_env_or_dev_tools_enabled
  end

  private

  def ensure_dev_env_or_dev_tools_enabled
    unless Rails.env.local? || Flipper.enabled?(:dev_tools)
      raise "Not in development environment"
    end
  end
end
