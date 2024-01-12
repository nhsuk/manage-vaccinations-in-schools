class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_school

  layout "registration"

  def new
    @registration_form = Registration.new
  end

  private

  def set_school
    @school = Location.find(params[:school_id])
  end
end
