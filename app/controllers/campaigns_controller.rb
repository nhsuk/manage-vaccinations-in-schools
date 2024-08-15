# frozen_string_literal: true

class CampaignsController < ApplicationController
  before_action :set_campaign, except: :index

  def index
    @campaigns = campaigns
  end

  def show
  end

  def sessions
    @in_progress_sessions = @campaign.sessions.in_progress
    @future_sessions = @campaign.sessions.future
    @past_sessions = @campaign.sessions.past
  end

  private

  def campaigns
    @campaigns ||= policy_scope(Campaign).active
  end

  def set_campaign
    @campaign = campaigns.find(params[:id])
  end
end
