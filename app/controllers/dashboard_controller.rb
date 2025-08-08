# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  layout "full"

  def index
    @notices_count =
      if policy(:notices).index?
        ImportantNotices.call(patient_scope: policy_scope(Patient)).length
      end
  end
end
