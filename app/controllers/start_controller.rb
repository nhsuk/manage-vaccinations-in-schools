# frozen_string_literal: true

class StartController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  skip_before_action :store_user_location!
  before_action :store_redirect_uri!

  def index
    redirect_after_choosing_org if current_user
  end
end
