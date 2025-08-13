# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticationConcern
  include CIS2LogoutConcern

  skip_before_action :authenticate_user!
  skip_before_action :ensure_team_is_selected
  skip_after_action :verify_policy_scoped
  skip_before_action :verify_authenticity_token, only: [:cis2_logout]
  skip_before_action :authenticate_basic, only: [:cis2_logout]

  before_action :verify_cis2_response, only: %i[cis2]

  def cis2
    set_cis2_session_info

    if !selected_cis2_role_is_valid?
      redirect_to users_role_not_found_path
    elsif !selected_cis2_org_is_registered?
      redirect_to users_organisation_not_found_path
    elsif !selected_cis2_workgroup_is_valid?
      redirect_to users_workgroup_not_found_path
    else
      @user = User.find_or_create_from_cis2_oidc(user_cis2_info, valid_teams)

      # Track which users have authorisation to supply using the PGD protocol.
      @user.update!(show_in_suppliers: cis2_info.is_nurse?)

      # give them a session token for the reporting app also
      @user.update!(reporting_api_session_token: SecureRandom.hex(32))

      # Force is set to true because the `session_token` might have changed
      # even if the same user is logging in.
      sign_in @user, event: :authentication, force: true
      # We have to split sign_in and redirect methods up, so we can supply the
      # allow_other_host param to the redirect. This is so that we can
      # redirect to the reporting app which will be running on another host/port
      # Note that safety checks on the host are now done in the
      # after_sign_in_path_for method, so this doesn't allow arbitrary URLs
      redirect_after_choosing_org
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
        @user.update!(session_token: nil, reporting_api_session_token: nil)
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

  def user_cis2_info = request.env["omniauth.auth"]

  def raw_cis2_info
    user_cis2_info["extra"]["raw_info"]
  end

  def valid_teams
    Team.joins(:organisation).where(
      workgroup: selected_cis2_nrbac_role["workgroups"],
      organisation: {
        ods_code: selected_cis2_org["org_code"]
      }
    )
  end

  def set_cis2_session_info
    cis2_info.update!(
      organisation_name: selected_cis2_org["org_name"],
      organisation_code: selected_cis2_org["org_code"],
      role_name: selected_cis2_nrbac_role["role_name"],
      role_code: selected_cis2_nrbac_role["role_code"],
      activity_codes: selected_cis2_nrbac_role["activity_codes"] || [],
      workgroups: selected_cis2_nrbac_role["workgroups"] || [],
      has_other_roles: raw_cis2_info["nhsid_nrbac_roles"].length > 1
    )
  end

  def after_omniauth_failure_path_for(_scope)
    root_path
  end
end
