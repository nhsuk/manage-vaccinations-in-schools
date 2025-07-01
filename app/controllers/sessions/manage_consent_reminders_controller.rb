# frozen_string_literal: true

class Sessions::ManageConsentRemindersController < ApplicationController
  before_action :set_session

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
