class ConsentForms::BaseController < ApplicationController
  private

  def set_header_path
    @header_path = start_session_consent_forms_path
  end

  def set_service_name
    @service_name = "Give or refuse consent for vaccinations"
  end
end
