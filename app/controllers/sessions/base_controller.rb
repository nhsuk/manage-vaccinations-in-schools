# frozen_string_literal: true

class Sessions::BaseController < ApplicationController
  before_action :set_session

  private

  def set_session
    @session =
      policy_scope(Session).includes(
        :location_programme_year_groups,
        programmes: :vaccines
      ).find_by!(slug: params[:session_slug])
  end
end
