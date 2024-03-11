class ReportsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: %i[index]

  def index
  end
end
