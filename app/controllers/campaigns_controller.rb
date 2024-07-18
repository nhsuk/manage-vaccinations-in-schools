# frozen_string_literal: true

class CampaignsController < ApplicationController
  before_action :set_campaign, except: :index

  def index
    @campaigns = policy_scope(Campaign)
  end

  def show
  end

  def sessions
    @in_progress_sessions = @campaign.sessions.in_progress
    @future_sessions = @campaign.sessions.future
    @past_sessions = @campaign.sessions.past
  end

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:id])
  end
end
