# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  layout "full"

  def index
    authorize :dashboard
  end
end
