# frozen_string_literal: true

class API::Testing::BaseController < ActionController::API
  before_action :ensure_local_or_feature_enabled

  private

  def ensure_local_or_feature_enabled
    unless Rails.env.local? || Flipper.enabled?(:testing_api)
      render status: :forbidden
    end
  end

  def log_destroy(query)
    where_clause = query.where_clause
    @log_time ||= Time.zone.now
    query.delete_all
    response.stream.write(
      "#{query.model.name}.where(#{where_clause.to_h}): #{Time.zone.now - @log_time}s\n"
    )
    @log_time = Time.zone.now
  end
end
