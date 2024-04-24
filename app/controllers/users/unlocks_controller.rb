module Users
  class UnlocksController < Devise::UnlocksController
    layout "two_thirds"

    skip_after_action :verify_policy_scoped
  end
end
