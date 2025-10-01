# frozen_string_literal: true

module InspectAuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    def ensure_ops_tools_feature_enabled
      unless Flipper.enabled?("ops_tools")
        raise ActionController::RoutingError, "Not Found"
      end
    end
  end
end
