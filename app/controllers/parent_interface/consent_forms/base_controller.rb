# frozen_string_literal: true

module ParentInterface
  class ConsentForms::BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_policy_scoped

    prepend_before_action :set_consent_form
    before_action :authenticate_consent_form_user!
    before_action :set_privacy_policy_url

    private

    def set_consent_form
      @consent_form =
        ConsentForm.includes(:programmes, :vaccines).find(
          params[:consent_form_id] || params[:id]
        )
      @organisation = @consent_form.organisation
      @programmes = @consent_form.programmes
      @session = @consent_form.original_session
      @team = @consent_form.team
    end

    def authenticate_consent_form_user!
      unless session[:consent_form_id] == @consent_form.id
        redirect_to @header_path
      end
    end

    def set_header_path
      @header_path =
        start_parent_interface_consent_forms_path(@session, @programmes.first)
    end

    def set_service_name
      @service_name = "Give or refuse consent for vaccinations"
    end

    def set_secondary_navigation
      @show_secondary_navigation = false
    end

    def set_service_guide_url
      @service_guide_url = nil
    end

    def set_privacy_policy_url
      @privacy_policy_url = @organisation.privacy_policy_url
    end
  end
end
