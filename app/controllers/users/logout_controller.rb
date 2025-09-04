# frozen_string_literal: true

class Users::LogoutController < ApplicationController
  layout "two_thirds"

  skip_after_action :verify_policy_scoped

  def show
  end
end
