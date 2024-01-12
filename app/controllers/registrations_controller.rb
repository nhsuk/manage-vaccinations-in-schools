class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_school

  layout "registration"

  def new
    @registration_form = Registration.new
  end

  def create
    @registration_form = Registration.new(registration_params)
    @registration_form.location = @school

    if @registration_form.save
      redirect_to confirmation_registration_path
    else
      render :new
    end
  end

  def confirmation
  end

  private

  def set_school
    @school = Location.find(params[:school_id])
  end

  def registration_params
    params.require(:registration).permit(
      :parent_name,
      :parent_relationship,
      :parent_relationship_other,
      :parent_email,
      :parent_phone
    )
  end
end
