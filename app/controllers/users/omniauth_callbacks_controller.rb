# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticationConcern
  include CIS2LogoutConcern

  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped
  skip_before_action :verify_authenticity_token, only: [:cis2_logout]
  skip_before_action :authenticate_basic, only: [:cis2_logout]

  before_action :verify_cis2_response, only: %i[cis2]

  def cis2
    set_cis2_session_info

    if !selected_cis2_workgroup_is_valid?
      redirect_to users_workgroup_not_found_path
    elsif !selected_cis2_role_is_valid?
      redirect_to users_role_not_found_path
    elsif !selected_cis2_org_is_registered?
      redirect_to users_organisation_not_found_path
    else
      @user = User.find_or_create_from_cis2_oidc(user_cis2_info)

      # Force is set to true because the `session_token` might have changed
      # even if the same user is logging in.
      sign_in_and_redirect @user, event: :authentication, force: true
    end
  rescue StandardError => e
    unless Rails.env.production?
      user_info = request.env["omniauth.auth"].to_h
      Rails.logger.error(
        "ID token: #{user_info.dig("credentials", "id_token")}"
      )
      Rails.logger.error(
        user_info.dig("extra", "raw_info").slice("nhsid_nrbac_roles").to_h
      )
      Rails.logger.error(
        user_info.dig("extra", "raw_info").slice("nhsid_user_orgs").to_h
      )
      Rails.logger.error(
        user_info.dig("extra", "raw_info").slice("selected_roleid").to_h
      )
    end
    raise e
  end

  def cis2_logout
    logout_token = params[:logout_token]

    if validate_logout_token(logout_token)
      if @sid.blank? || @user.session_token == @sid
        @user.update!(session_token: nil)
      end

      render json: {}, status: :ok
    else
      render json: { error: "Invalid logout token" }, status: :bad_request
    end
  end

  def logout
    signed_out =
      (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    flash[:notice] = "You have been logged out" if signed_out
    redirect_to after_sign_out_path_for(resource_name)
  end

  private

  def verify_cis2_response
    if user_cis2_info["uid"] != user_cis2_info["extra"]["raw_info"]["sub"]
      raise "cis2 authentication: uid does not match sub cliam"
    elsif Integer(raw_cis2_info[:id_assurance_level]) < 3
      raise "cis2 authentication: id_assurance_level too low" \
              " (#{raw_cis2_info[:id_assurance_level]} != 3)"
    elsif Integer(raw_cis2_info[:authentication_assurance_level]) <
          Settings.cis2.min_authentication_assurance_level
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

  def set_cis2_session_info
    session["cis2_info"] = {
      "selected_org" => {
        "name" => selected_cis2_org["org_name"],
        "code" => selected_cis2_org["org_code"]
      },
      "selected_role" => {
        "name" => selected_cis2_nrbac_role["role_name"],
        "code" => selected_cis2_nrbac_role["role_code"],
        "workgroups" => selected_cis2_nrbac_role["workgroups"]
      },
      "has_other_roles" => raw_cis2_info["nhsid_nrbac_roles"].length > 1
    }
  end

  def after_omniauth_failure_path_for(_scope)
    root_path
  end
end
