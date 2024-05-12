class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: %i[new create confirmation]

  before_action :set_school

  layout "registration"

  def new
    @registration_form = Registration.new
  end

  def create
    @registration_form = Registration.new(registration_params)
    @registration_form.location = @school

    if @registration_form.save
      redirect_to confirmation_school_registration_path
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
      :use_common_name,
      :user_research_observation_agreed
    )
  end
end
