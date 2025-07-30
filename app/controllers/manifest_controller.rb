# frozen_string_literal: true

class ManifestController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  before_action :set_assets_name

  def show
    respond_to do |format|
      format.json do
        render "manifest/show", content_type: "application/manifest+json"
      end
    end
  end

  private

  def set_assets_name
    @assets_name = params[:name] || "application"
  end
end
