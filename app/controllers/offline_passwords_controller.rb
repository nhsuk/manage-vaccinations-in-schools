# frozen_string_literal: true

class OfflinePasswordsController < ApplicationController
  def new
    @password = OfflinePassword.new
  end

  def create
    @password = OfflinePassword.new(password_params)

    if @password.save
      redirect_to sessions_path,
                  flash: {
                    success: "Campaign saved, you can now go offline"
                  }
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:offline_password).permit(:password, :password_confirmation)
  end
end
