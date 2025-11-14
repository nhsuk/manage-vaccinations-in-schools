# frozen_string_literal: true

class Sessions::BaseController < ApplicationController
  before_action :set_session

  private

  def set_session
    @session =
      policy_scope(Session).includes(:session_programme_year_groups).find_by!(
        slug: params[:session_slug]
      )
  end
end
