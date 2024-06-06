class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def cis2
  end
  alias_method :openid_connect, :cis2
end
