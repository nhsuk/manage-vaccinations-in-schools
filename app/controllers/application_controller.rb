class ApplicationController < ActionController::Base
  if Rails.env.production?
    http_basic_authenticate_with name: Settings.support_username,
                                 password: Settings.support_password,
                                 message:
                                   "THIS IS NOT A PRODUCTION NHS.UK SERVICE"
  end

  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)
end
