# frozen_string_literal: true

class API::Testing::BaseController < ActionController::API
  before_action :ensure_local_or_feature_enabled

  private

  def ensure_local_or_feature_enabled
    unless Rails.env.local? || Flipper.enabled?(:testing_api)
      render status: :forbidden
    end
  end
end
