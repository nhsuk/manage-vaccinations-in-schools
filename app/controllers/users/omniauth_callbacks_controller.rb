class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def openid_connect
  end
end
