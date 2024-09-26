# frozen_string_literal: true

class TeamsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def settings
    @team = current_user.team
  end
end
