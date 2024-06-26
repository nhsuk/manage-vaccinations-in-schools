# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    skip_after_action :verify_policy_scoped

    layout "one_half"
  end
end
