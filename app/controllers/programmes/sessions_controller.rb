# frozen_string_literal: true

class Programmes::SessionsController < ApplicationController
  before_action :set_programme

  layout "full"

  def index
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .for_current_academic_year
        .includes(:location, :session_dates)
        .order("locations.name")
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
