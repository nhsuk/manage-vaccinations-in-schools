# frozen_string_literal: true

module AuthenticationConcern
  extend ActiveSupport::Concern

  CIS2_WORKGROUP = "schoolagedimmunisations"

  included do
    private

    # only return true if the given URL is part of this domain (relative or absolute)
    # or part of the mavis reporting app, or localhost (to allow devs some leeway)
    def is_valid_redirect?(url)
      url.start_with?("/") || url.start_with?(request.base_url) ||
        url.start_with?(
          Settings.mavis_reporting_app.root_url || "http://localhost"
        )
    end

    def authenticate_user!
      if !user_signed_in?
        if request.path != start_path && request.path != new_users_organisations_path
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
          redirect_to users_organisation_not_found_path
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
      workgroups.present? && CIS2_WORKGROUP.in?(workgroups)
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

    def store_redirect_after_login!
      if params.key?(:redirect_after_login)
        session[:redirect_after_login] = params.fetch(:redirect_after_login)
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

    def token_error!(token)
      if token.blank?
        render json: {errors: "Unauthorized"}, status: :unauthorized and return
      else
        render json: {errors: "Forbidden"}, status: :forbidden and return
      end
    end

    def authenticate_app_by_token!
      possible_tokens = []
      # auth_token_by_param means tokens could appear in logs => it's for dev environments only
      # hence making it controlled by feature flag
      possible_tokens << params[:auth] if Flipper.enabled?(:auth_token_by_param)
      # auth_token_by_header is safer, hence having its own feature flag
      possible_tokens << request.headers["Authorization"] if Flipper.enabled?(:auth_token_by_header)
      
      token = possible_tokens.find { it == Settings.mavis_reporting_app.secret }
      token_error!(token) unless token
    end

    def jwt_if_given
      params[:jwt] || request.headers['Authorization']&.gsub(/(Bearer\s+)?([:alnum:]*)/, '\2')
    end

    def authenticate_user_by_jwt!
      jwt = jwt_if_given
      jwt_info = decode_jwt( jwt )
      if jwt_info
        data = jwt_info.first['data']
        @current_user = User.find_by(
          id: data['user']['id'],
          session_token: data['user']['session_token'],
          pwd_auth_session_token: data['user']['pwd_auth_session_token']
        )
        if @current_user
          session['user'] = data['user']
          session['cis2_info'] = data['cis2_info']
          authenticate_user!
        else
          session.clear
          Rails.logger.warn "Couldn't find user id #{data['user']['id']} with given session_token and pwd_auth_session_token"
          token_error!(jwt)
        end
      end
    rescue JWT::DecodeError, NoMethodError => e
      Rails.logger.warn "invalid JWT"
      token_error!(jwt)
    end

    def add_token_to(url, user)
      uri = Addressable::URI.parse(url)
      user_token =
        OneTimeToken.find_or_generate_for!(
          user_id: user.id,
          cis2_info: session["cis2_info"]
        ).token
      uri.query_values = (uri.query_values || {}).merge("token" => user_token)
      uri.to_s
    end

    def reporting_app_redirect_url_with_token_for(user)
      url = session["redirect_after_login"]
      if url.present?
        add_token_to(url, user)
      else
        nil
      end
    end

    def after_sign_in_path_for(scope)
      urls = [
        reporting_app_redirect_url_with_token_for(current_user),
        stored_location_for(scope),
        dashboard_path
      ]
      urls.compact.find { is_valid_redirect?(it) && (it != request.fullpath) && (it != new_users_organisations_path) }
    end

    def redirect_after_choosing_org
      url = after_sign_in_path_for(current_user)
      session.delete(:redirect_after_login)
      redirect_to url, allow_other_host: is_valid_redirect?(url)
    end

    def user_signed_in?
      super && (Settings.cis2.enabled ? cis2_session? : true)
    end

    def decode_jwt(jwt)
      if jwt
        JWT.decode(jwt, Settings.mavis_reporting_app.secret, true, { algorithm: 'HS512' })
      else
        nil
      end
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
