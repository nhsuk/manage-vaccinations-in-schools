# frozen_string_literal: true

class CampaignsController < ApplicationController
  before_action :set_campaign, except: %i[index create]

  skip_after_action :verify_policy_scoped, only: :create

  layout "full"

  def index
    @campaigns = campaigns
  end

  def create
    campaign = Campaign.create!(team: current_user.team)
    redirect_to campaign_edit_path(campaign, Wicked::FIRST_STEP)
  end

  def show
  end

  def patients
    @patients = @campaign.patients.active
  end

  def sessions
    @in_progress_sessions = @campaign.sessions.active.in_progress
    @future_sessions = @campaign.sessions.active.future
    @past_sessions = @campaign.sessions.active.past
  end

  private

  def campaigns
    @campaigns ||= policy_scope(Campaign).active
  end

  def set_campaign
    @campaign = campaigns.find(params[:id])
  end
end
