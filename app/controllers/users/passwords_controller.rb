module Users
  class PasswordsController < Devise::PasswordsController
    layout "two_thirds"

    skip_after_action :verify_policy_scoped
  end
end
