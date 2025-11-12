# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  layout "full"

  def index
    @notices_count =
      (policy_scope(ImportantNotice).count if policy(ImportantNotice).index?)
  end
end
