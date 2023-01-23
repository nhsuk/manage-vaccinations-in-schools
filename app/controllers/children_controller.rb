class ChildrenController < ApplicationController
  before_action :set_campaign, only: %i[index]

  # GET /children
  def index
    @children = @campaign.children
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_child
    @child = Child.find(params[:id])
  end

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end
end
