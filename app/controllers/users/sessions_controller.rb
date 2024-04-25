# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_after_action :verify_policy_scoped

  layout "one_half"
end
