class SchoolsController < ApplicationController
  before_action :set_school, only: [:show]
  before_action :set_unmatched_consent_responses, only: [:show]

  def show
  end

  def close_registration
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
