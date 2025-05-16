# frozen_string_literal: true

module AuthenticationConcern
  extend ActiveSupport::Concern

  CIS2_WORKGROUP = "schoolagedimmunisations"
  CIS2_OPS_WORKGROUP = "mavissupport"

  included do
    private

    def authenticate_user!
      return handle_unauthenticated_user unless user_signed_in?
      return unless cis2_session?

      user_is_ops? ? handle_ops_user : handle_regular_user
    end

    def handle_unauthenticated_user
      store_location_for(:user, request.fullpath) if request.path != start_path

      if Settings.cis2.enabled || request.path != new_user_session_path
        flash[:info] = "You must be logged in to access this page."
        redirect_to start_path and return
      end
    end

    def handle_ops_user
      redirect_to inspect_dashboard_path unless path_is_ops?
    end

    def handle_regular_user
      if path_is_ops?
        redirect_to users_unauthorized_path
      elsif !selected_cis2_workgroup_is_valid?
        redirect_to users_workgroup_not_found_path
      elsif !selected_cis2_role_is_valid?
        redirect_to users_role_not_found_path
      elsif !selected_cis2_org_is_registered?
        redirect_to users_organisation_not_found_path
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
      session.dig("cis2_info", "selected_role", "workgroups")&.include?(
        CIS2_WORKGROUP
      )
    end

    def user_is_ops?
      session.dig("cis2_info", "selected_role", "workgroups")&.include?(
        CIS2_OPS_WORKGROUP
      )
    end

    def path_is_ops?
      request.path.start_with?("/inspect")
    end

    def valid_cis2_roles
      %w[S8000:G8000:R8001 S8000:G8001:R8006]
    end

    def selected_cis2_role_is_valid?
      session["cis2_info"]["selected_role"]["code"].in? valid_cis2_roles
    end

    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? &&
        !request.xhr? && !turbo_frame_request?
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

    def after_sign_in_path_for(scope)
      stored_location_for(scope) || dashboard_path
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
