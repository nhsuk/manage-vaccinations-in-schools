# frozen_string_literal: true

module AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    # only return true if the given URL is part of this domain (relative or absolute)
    # or part of the mavis reporting app, or localhost (to allow devs some leeway)
    def is_valid_redirect?(url)
      url.start_with?("/") || url.start_with?(request.base_url) ||
        url.start_with?(
          Settings.reporting_api.client_app.root_url || "http://localhost"
        )
    end

    def authenticate_user!
      if !user_signed_in?
        if request.path != start_path && request.path != new_users_teams_path
          store_location_for(:user, request.fullpath)
        end

        if Settings.cis2.enabled || request.path != new_user_session_path
          flash[:info] = "You must be logged in to access this page."
          redirect_to start_path
        end
      elsif cis2_session?
        if !selected_cis2_workgroup_is_valid?
          redirect_to users_workgroup_not_found_path
        elsif !selected_cis2_role_is_valid?
          redirect_to users_role_not_found_path
        elsif !selected_cis2_org_is_registered?
          redirect_to users_team_not_found_path
        end
      end
    end

    def cis2_session?
      session.key?(:cis2_info)
    end

    def selected_cis2_org_is_registered?
      Organisation.exists?(
        ods_code: session["cis2_info"]["selected_org"]["code"]
      )
    end

    def selected_cis2_workgroup_is_valid?
      workgroups = session.dig("cis2_info", "selected_role", "workgroups")
      workgroups.present? && User::CIS2_WORKGROUP.in?(workgroups)
    end

    def valid_cis2_roles = [User::CIS2_NURSE_ROLE, User::CIS2_ADMIN_ROLE]

    def selected_cis2_role_is_valid?
      session["cis2_info"]["selected_role"]["code"].in? valid_cis2_roles
    end

    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? &&
        !request.xhr? && !turbo_frame_request?
    end

    def store_redirect_uri!
      if params.key?(:redirect_uri)
        session[:redirect_uri] = params.fetch(:redirect_uri)
      end
    end

    def store_user_location!
      return unless user_signed_in?
      return unless storable_location?

      store_location_for(:user, request.fullpath)
    end

    def authenticate_basic
      if Flipper.enabled? :basic_auth
        authenticated =
          authenticate_with_http_basic do |username, password|
            username == Rails.application.credentials.support_username &&
              password == Rails.application.credentials.support_password
          end

        unless authenticated
          request_http_basic_authentication "Application", <<~MESSAGE
        Access is currently restricted to authorised users only.
      MESSAGE
        end
      end
    end

    def add_auth_code_to(url, user)
      uri = Addressable::URI.parse(url)
      auth_code =
        Reporting::OneTimeToken.find_or_generate_for!(
          user:,
          cis2_info: session["cis2_info"]
        ).token
      uri.query_values = (uri.query_values || {}).merge("code" => auth_code)
      uri.to_s
    end

    def reporting_app_redirect_uri_with_auth_code_for(user)
      if Flipper.enabled?(:reporting_api)
        url = session["redirect_uri"]
        url.present? ? add_auth_code_to(url, user) : nil
      end
    end

    def after_sign_in_path_for(scope)
      urls = []
      if Flipper.enabled?(:reporting_api)
        urls << reporting_app_redirect_uri_with_auth_code_for(current_user)
      end
      urls += [stored_location_for(scope), dashboard_path]
      urls.compact.find do
        is_valid_redirect?(it) && (it != request.fullpath) &&
          (it != new_users_teams_path)
      end
    end

    def redirect_after_choosing_org
      url = after_sign_in_path_for(current_user)
      session.delete(:redirect_uri)
      redirect_to url, allow_other_host: is_valid_redirect?(url)
    end

    def user_signed_in?
      super && (Settings.cis2.enabled ? cis2_session? : true)
    end

    def set_user_cis2_info
      return unless current_user

      current_user.cis2_info = session["cis2_info"]
    end

    def selected_cis2_nrbac_role
      return {} if raw_cis2_info["selected_roleid"].blank?

      @selected_cis2_nrbac_role ||=
        raw_cis2_info["nhsid_nrbac_roles"].find do
          _1["person_roleid"] == raw_cis2_info["selected_roleid"]
        end
    end

    def selected_cis2_org
      return {} if selected_cis2_nrbac_role.empty?

      @selected_cis2_org ||=
        raw_cis2_info["nhsid_user_orgs"].find do
          _1["org_code"] == selected_cis2_nrbac_role["org_code"]
        end
    end
  end
end
