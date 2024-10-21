# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticationConcern
  include CIS2LogoutConcern

  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped
  skip_before_action :verify_authenticity_token, only: %i[cis2 cis2_logout]

  before_action :verify_cis2_response, only: %i[cis2]

  def cis2
    set_cis2_session_info

    if !selected_cis2_org_is_registered?
      redirect_to users_team_not_found_path
    elsif !selected_cis2_role_is_valid?
      redirect_to users_role_not_found_path
    else
      @user = User.find_or_create_from_cis2_oidc(user_cis2_info)
      sign_in_and_redirect @user, event: :authentication
    end
  end

  def cis2_logout
    logout_token = params[:logout_token]

    if validate_logout_token(logout_token)
      sign_out(@user) if @user
      render json: {}, status: :ok
    else
      render json: { error: "Invalid logout token" }, status: :bad_request
    end
  end

  private

  def verify_cis2_response
    if user_cis2_info["uid"] != user_cis2_info["extra"]["raw_info"]["sub"]
      raise "cis2 authentication: uid does not match sub cliam"
    elsif Integer(raw_cis2_info[:id_assurance_level]) < 3
      raise "cis2 authentication: id_assurance_level too low" \
              " (#{raw_cis2_info[:id_assurance_level]} != 3)"
    elsif Integer(raw_cis2_info[:authentication_assurance_level]) <
          Settings.cis2.authentication_assurance_level
      raise "cis2 authentication: authentication_assurance_level too low" \
              " (#{raw_cis2_info[:authentication_assurance_level]} < " \
              " #{Settings.cis2.authentication_assurance_level})"
    elsif Time.zone.at(raw_cis2_info[:auth_time]) < 5.minutes.ago
      raise "cis2 authentication: auth_time too old" \
              " (#{raw_cis2_info[:auth_time]})"
    end
  end

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

  def set_cis2_session_info
    session["cis2_info"] = {
      "selected_org" => {
        "name" => selected_cis2_org["org_name"],
        "code" => selected_cis2_org["org_code"]
      },
      "selected_role" => {
        "name" => selected_cis2_nrbac_role["role_name"],
        "code" => selected_cis2_nrbac_role["role_code"]
      },
      "has_other_roles" => raw_cis2_info["nhsid_nrbac_roles"].length > 1
    }
  end
end
