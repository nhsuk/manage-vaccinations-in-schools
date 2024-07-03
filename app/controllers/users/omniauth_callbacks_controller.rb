# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def cis2
    user_info = request.env["omniauth.auth"]
    raw_info = user_info["extra"]["raw_info"]
    selected_role = raw_info["selected_roleid"]
    nrbac_role =
      raw_info["nhsid_nrbac_roles"].find do
        _1["person_roleid"] == selected_role
      end

    team = Team.find_by(ods_code: nrbac_role["org_code"])
    if team.nil?
      @selected_org =
        raw_info["nhsid_user_orgs"].find do
          _1["org_code"] == nrbac_role["org_code"]
        end

      flash[:org_name] = @selected_org["org_name"]
      flash[:org_code] = @selected_org["org_code"]
      redirect_to team_not_found_path
      false
    else
      @user = User.find_or_create_user_from_cis2_oidc(user_info)
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
    end
  end
end
