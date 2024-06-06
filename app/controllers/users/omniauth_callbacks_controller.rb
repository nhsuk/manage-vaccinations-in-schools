class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def cis2
    @user =
      User.find_or_create_user_from_cis2_oidc(request.env["omniauth.auth"])
    sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
  end
  alias_method :openid_connect, :cis2
end
