# frozen_string_literal: true

class ManifestController < ActionController::API
  include ApplicationHelper

  before_action :set_assets_name

  def show
    render_block = -> do
      render "manifest/show", content_type: "application/manifest+json"
    end

    if params[:digest] == manifest_digest
      http_cache_forever(public: true, &render_block)
    else
      expires_in 1.hour, public: true
      render_block
    end
  end

  private

  def set_assets_name
    @assets_name = params[:name] || "application"
  end
end
