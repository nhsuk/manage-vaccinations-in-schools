# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_after_action :verify_policy_scoped, only: :index

  helper_method :dashboard_cards_partial, :is_upload_only?

  layout "full"

  def index
    @notices_count =
      if policy(:notices).index?
        ImportantNotices.call(patient_scope: policy_scope(Patient)).length
      end
  end

  def is_upload_only?
    current_team.is_upload_only? && Flipper.enabled?(:bulk_upload)
  end

  def dashboard_cards_partial
    is_upload_only? ? "dashboard_cards_upload_only" : "dashboard_cards_default"
  end
end
