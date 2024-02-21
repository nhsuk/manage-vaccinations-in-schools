class ConsentFormsController < ApplicationController
  before_action :set_consent_form, only: [:show]
  before_action :set_school, only: [:show]
  before_action :set_session, only: [:unmatched_responses]

  def show
  end

  def unmatched_responses
    @unmatched_consent_responses = @session.consent_forms.unmatched.recorded
  end

  private

  def set_consent_form
    @consent_form = ConsentForm.find(params[:id])
  end

  def set_school
    @school = @consent_form.session.location
  end

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end
end
