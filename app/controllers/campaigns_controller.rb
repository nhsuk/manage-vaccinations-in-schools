class CampaignsController < ApplicationController
  before_action :set_campaign, only: %i[show]

  def index
  end

  def show
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
