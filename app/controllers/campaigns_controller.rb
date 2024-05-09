class CampaignsController < ApplicationController
  def index
    @campaigns = policy_scope(Campaign)
  end

  def show
    @campaign = policy_scope(Campaign).find(params[:id])
    @in_progress_sessions = @campaign.sessions.in_progress
    @future_sessions = @campaign.sessions.future
    @past_sessions = @campaign.sessions.past
  end
end
