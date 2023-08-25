class ConsentForms::DateOfBirthController < ApplicationController
  before_action :set_session, only: %i[edit update]
  before_action :set_consent_form, only: %i[edit update]
  before_action :set_return_to, only: %i[edit update]

  layout "two_thirds"

  def update
    @consent_form.assign_attributes(update_params)
    if @consent_form.save(context: :edit_date_of_birth)
      if @return_to.present?
        redirect_to @return_to
      else
        redirect_to session_consent_form_confirm_path(@session)
      end
    else
      render action: :edit
    end
  end

  def edit
  end

  private

  def set_consent_form
    @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
  end

  def set_return_to
    @return_to = params[:return_to]
  end

  def set_session
    @session = Session.find(params.fetch(:session_id) { params.fetch(:id) })
  end

  def update_params
    params.fetch(:consent_form, {}).permit(
      %i[date_of_birth(3i) date_of_birth(2i) date_of_birth(1i)]
    )
  end
end
