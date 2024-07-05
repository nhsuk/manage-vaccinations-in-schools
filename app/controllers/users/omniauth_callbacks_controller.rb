# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def cis2
    team = Team.find_by(ods_code: selected_cis2_nrbac_role["org_code"])
    if team.nil?
      flash[:cis2_info] = {
        org_name: selected_cis2_org["org_name"],
        org_code: selected_cis2_org["org_code"],
        has_other_roles: raw_cis2_info["nhsid_nrbac_roles"].length > 1
      }

      redirect_to users_team_not_found_path
    else
      @user = User.find_or_create_user_from_cis2_oidc(user_cis2_info)
      sign_in_and_redirect @user, event: :authentication
    end
  end

  private

  def user_cis2_info
    request.env["omniauth.auth"]
  end

  def raw_cis2_info
    user_cis2_info["extra"]["raw_info"]
  end

  def selected_cis2_nrbac_role
    @selected_cis2_nrbac_role ||=
      raw_cis2_info["nhsid_nrbac_roles"].find do
        _1["person_roleid"] == raw_cis2_info["selected_roleid"]
      end
  end

  def selected_cis2_org
    @selected_cis2_org ||=
      raw_cis2_info["nhsid_user_orgs"].find do
        _1["org_code"] == selected_cis2_nrbac_role["org_code"]
      end
  end
end
