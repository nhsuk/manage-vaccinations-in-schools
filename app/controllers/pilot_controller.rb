# frozen_string_literal: true

class PilotController < ApplicationController
  skip_after_action :verify_policy_scoped

  layout "two_thirds"

  def manage
  end
end
