# frozen_string_literal: true

class Users::ErrorsController < ::ApplicationController
  skip_before_action :store_user_location!
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def organisation_not_found
    if session.key? :cis2_info
      @cis2_info = session[:cis2_info].with_indifferent_access
      render status: :not_found
    else
      redirect_to root_path
    end
  end

  def role_not_found
    if session.key? :cis2_info
      @cis2_info = session[:cis2_info].with_indifferent_access
      render status: :not_found
    else
      redirect_to root_path
    end
  end
end
