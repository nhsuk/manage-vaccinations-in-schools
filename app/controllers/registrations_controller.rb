class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_school

  layout "registration"

  def slug
    redirect_to action: :new
  end

  def new
    if Flipper.enabled?(:registration_open) && @school.registration_open?
      @registration_form = Registration.new
      render "new"
    else
      render "closed"
    end
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
      :address_line_1,
      :address_line_2,
      :address_postcode,
      :address_town,
      :common_name,
      :consent_response_confirmed,
      :date_of_birth,
      :data_processing_agreed,
      :first_name,
      :last_name,
      :nhs_number,
      :parent_email,
      :parent_name,
      :parent_phone,
      :parent_relationship,
      :parent_relationship_other,
      :terms_and_conditions_agreed,
      :use_common_name
    )
  end
end
