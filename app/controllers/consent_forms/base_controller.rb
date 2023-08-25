class ConsentForms::BaseController < ApplicationController
  private

  def set_service_name
    @service_name = "Give or refuse consent for vaccinations"
  end
end
