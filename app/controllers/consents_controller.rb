class ConsentsController < ApplicationController
  before_action :set_session

  def index
  end

  private

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end
end
