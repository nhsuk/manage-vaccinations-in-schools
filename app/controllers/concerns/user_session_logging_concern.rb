# frozen_string_literal: true

module UserSessionLoggingConcern
  extend ActiveSupport::Concern

  included { prepend_around_action :add_user_session_id_log_tag }

  private

  def add_user_session_id_log_tag(&block)
    SemanticLogger.tagged(user_session_id: request.session.id, &block)
  end
end
