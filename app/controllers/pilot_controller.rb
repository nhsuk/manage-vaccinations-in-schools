# frozen_string_literal: true

class PilotController < ApplicationController
  skip_after_action :verify_policy_scoped

  def manage
  end
end
