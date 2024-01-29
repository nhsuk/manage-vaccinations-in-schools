class ContentController < ApplicationController
  include ContentHelper
  skip_before_action :authenticate_user!

  def accessibility_statement
    render_content_page :accessibility_statement
  end

  def privacy_policy
    render_content_page :privacy_policy
  end

  def privacy_policy_summary
    render_content_page :privacy_policy_summary
  end
end
