class SchoolsController < ApplicationController
  before_action :set_school,
                only: %i[close_registration handle_close_registration]

  layout "two_thirds", only: %i[close_registration]

  def show
  end

  def close_registration
  end

  def handle_close_registration
    if @school.update(registration_open: false)
      flash[:success] = "Pilot is now closed to new participants"
      redirect_to pilot_registrations_path
    else
      render :close_registration
    end
  end

  private

  def set_school
    # The only kind of locations we have currently are schools.
    @school = Location.find(params[:id])
  end

  def set_unmatched_consent_responses
    @unmatched_consent_responses = @school.consent_forms.unmatched.recorded
  end
end
