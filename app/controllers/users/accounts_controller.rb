# frozen_string_literal: true

module Users
  class AccountsController < ApplicationController
    before_action :set_user, only: %i[show update]

    skip_before_action :store_user_location!,
                       only: %i[team_not_found role_not_found]
    skip_before_action :authenticate_user!,
                       only: %i[team_not_found role_not_found]
    skip_after_action :verify_policy_scoped,
                      only: %i[team_not_found role_not_found]

    def show
    end

    def update
      if @user.update(user_params)
        redirect_to users_account_path(@user),
                    flash: {
                      success: "Your account details have been updated"
                    }
      else
        render :show, status: :unprocessable_entity
      end
    end

    def team_not_found
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

    private

    def set_user
      @user = policy_scope(User).find(params.fetch(:id))
    end

    def user_params
      params.require(:user).permit(:email, :family_name, :given_name)
    end
  end
end
