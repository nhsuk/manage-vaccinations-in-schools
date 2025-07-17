# frozen_string_literal: true

class Programmes::SessionsController < Programmes::BaseController
  def index
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .for_current_academic_year
        .includes(:location, :session_dates)
        .order("locations.name")
  end
end
