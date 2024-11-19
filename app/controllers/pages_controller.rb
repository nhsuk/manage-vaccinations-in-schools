# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: :start
  skip_before_action :store_user_location!, only: :start

  def start
  end
end
