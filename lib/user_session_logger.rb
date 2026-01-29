# frozen_string_literal: true

class UserSessionLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    user_session_id = env["rack.session"]&.id&.public_id

    if user_session_id.present?
      Rails.logger.tagged(user_session_id:) { @app.call(env) }
    else
      @app.call(env)
    end
  end
end
