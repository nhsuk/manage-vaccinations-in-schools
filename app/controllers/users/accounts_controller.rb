module Users
  class AccountsController < ApplicationController
    before_action :set_user

    layout "two_thirds"

    def show
    end

    def update
      if @user.update(user_params)
        redirect_to users_account_path(@user),
                    flash: {
                      success: "Your account has been updated"
                    }
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = policy_scope(User).find(params.fetch(:id))
    end

    def user_params
      params.require(:user).permit(:full_name, :email, :registration)
    end
  end
end
