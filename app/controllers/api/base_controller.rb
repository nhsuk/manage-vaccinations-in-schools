# frozen_string_literal: true

class API::BaseController < ActionController::API
  before_action :ensure_local_or_feature_enabled

  private

  def ensure_local_or_feature_enabled
    render status: :forbidden unless Rails.env.local? || Flipper.enabled?(:api)
  end
end
