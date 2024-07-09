# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_campaign

  def new
  end

  def create
  end

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:campaign_id])
  end
end
