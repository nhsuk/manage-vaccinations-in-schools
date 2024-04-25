module Users
  class UnlocksController < Devise::UnlocksController
    skip_after_action :verify_policy_scoped

    layout "one_half"
  end
end
