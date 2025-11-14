# frozen_string_literal: true

module UserSessionLoggingConcern
  extend ActiveSupport::Concern

  included { around_action :add_user_session_id_log_tag, prepend: true }

  private

  def add_user_session_id_log_tag(&block)
    SemanticLogger.tagged(user_session_id: request.session.id, &block)
  end
end
