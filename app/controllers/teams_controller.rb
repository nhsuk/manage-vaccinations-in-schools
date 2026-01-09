# frozen_string_literal: true

class TeamsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def show
    @team = authorize current_team
  end
end
