class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  layout "two_thirds"

  def index
  end
end
