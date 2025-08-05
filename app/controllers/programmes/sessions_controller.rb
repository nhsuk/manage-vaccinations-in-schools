# frozen_string_literal: true

class Programmes::SessionsController < Programmes::BaseController
  def index
    @sessions =
      policy_scope(Session)
        .has_programmes([@programme])
        .where(academic_year: @academic_year)
        .includes(:location, :session_dates)
        .order("locations.name")
  end
end
