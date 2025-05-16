# frozen_string_literal: true

module Inspect
  class DashboardController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_policy_scoped

    layout "full"

    def index
      @sample_patient_id = Patient.first.id
    end
  end
end
