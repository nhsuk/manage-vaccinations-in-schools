# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: :start

  layout "two_thirds"

  def start
  end
end
