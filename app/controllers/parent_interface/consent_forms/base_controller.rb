# frozen_string_literal: true

module ParentInterface
  class ConsentForms::BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_policy_scoped

    before_action :set_session
    before_action :set_consent_form
    before_action :authenticate_consent_form_user!
    before_action :set_privacy_policy_url

    private

    def set_session
      @session = Session.find(params.fetch(:session_id))
    end

    def set_consent_form
      @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
    end

    def authenticate_consent_form_user!
      unless session[:consent_form_id] == @consent_form.id
        redirect_to start_session_parent_interface_consent_forms_path(@session)
      end
    end

    def set_header_path
      @header_path = start_session_parent_interface_consent_forms_path
    end

    def set_service_name
      @service_name = "Give or refuse consent for vaccinations"
    end

    def set_privacy_policy_url
      @privacy_policy_url = @session.campaign.team.privacy_policy_url
    end
  end
end
