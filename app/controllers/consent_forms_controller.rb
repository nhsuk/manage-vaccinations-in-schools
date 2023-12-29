class ConsentFormsController < ApplicationController
  before_action :set_consent_form, only: [:show]
  before_action :set_school, only: [:show]

  def show
  end

  private

  def set_consent_form
    @consent_form = ConsentForm.find(params[:id])
  end

  def set_school
    @school = @consent_form.session.location
  end
end
