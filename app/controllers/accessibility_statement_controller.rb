# frozen_string_literal: true

class AccessibilityStatementController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
  end
end
