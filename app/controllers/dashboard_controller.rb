class DashboardController < ApplicationController
  # GET /dashboard
  def index
    @campaigns_by_type = Campaign.all.group_by(&:type)
  end
end
