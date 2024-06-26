# frozen_string_literal: true

class ContentController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  layout "two_thirds"
end
