# frozen_string_literal: true

class TeamsController < ApplicationController
  skip_after_action :verify_policy_scoped
  before_action :set_team

  layout "full"

  def contact_details
  end

  def sessions
  end

  def schools
  end

  def clinics
  end

  private

  def set_team
    @team = authorize current_team
  end
end
