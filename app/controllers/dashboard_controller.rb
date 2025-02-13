# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  layout "full"

  def index
    @important_notices =
      (policy_scope(Patient).with_notice.count if policy(:notices).index?)
  end
end
