# frozen_string_literal: true

module Inspect
  class DashboardController < ApplicationController
    include InspectAuthenticationConcern

    skip_before_action :ensure_team_is_selected
    skip_after_action :verify_policy_scoped
    before_action :ensure_ops_tools_feature_enabled

    layout "full"

    def index
      @sample_patient_id = Patient.first.id
    end
  end
end
