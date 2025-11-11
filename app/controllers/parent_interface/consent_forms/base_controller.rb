# frozen_string_literal: true

module ParentInterface
  class ConsentForms::BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_policy_scoped

    prepend_before_action :set_subteam
    prepend_before_action :set_programmes
    prepend_before_action :set_team
    prepend_before_action :set_session
    prepend_before_action :set_consent_form
    before_action :authenticate_consent_form_user!
    before_action :check_if_past_deadline!
    before_action :set_privacy_policy_url

    private

    def set_show_navigation
      @show_navigation = false
    end

    def set_consent_form
      @consent_form =
        ConsentForm.includes(:consent_form_programmes).find(
          params[:consent_form_id] || params[:id]
        )
    end

    def set_session
      if params[:session_slug]
        @session = Session.find_by!(slug: params[:session_slug])
      elsif @consent_form.present?
        @session = @consent_form.session
      end
    end

    def set_team
      @team =
        if @consent_form.present?
          @consent_form.team
        elsif @session.present?
          @session.team
        end
    end

    def set_programmes
      @programmes =
        if @consent_form.present?
          @consent_form.consent_form_programmes.map(&:programme)
        elsif @session.present? && params[:programme_types].present?
          types = params[:programme_types].split("-")
          @session.programmes.select { it.type.in?(types) }
        end
    end

    def set_subteam
      @subteam =
        if @consent_form.present?
          @consent_form.subteam
        elsif @session.present?
          @session.subteam
        end
    end

    def set_header_path
      @header_path =
        start_parent_interface_consent_forms_path(
          @session,
          @programmes.map(&:to_param).join("-")
        )
    end

    def set_assets_name
      @assets_name = "public"
    end

    def set_service_name
      @service_name = "Give or refuse consent for vaccinations"
    end

    def set_service_url
      @service_url =
        "https://www.give-or-refuse-consent-for-vaccinations.nhs.uk"
    end

    def set_secondary_navigation
      @show_secondary_navigation = false
    end

    def set_service_guide_url
      @service_guide_url = nil
    end

    def set_privacy_policy_url
      @privacy_policy_url = @team.privacy_policy_url
    end

    def authenticate_consent_form_user!
      unless session[:consent_form_id] == @consent_form.id
        redirect_to @header_path
      end
    end

    def check_if_past_deadline!
      return if @session.unscheduled?
      return if @session.open_for_consent?

      redirect_to deadline_passed_parent_interface_consent_forms_path(
                    @session.slug,
                    @programmes.map(&:type).join("-")
                  )
    end
  end
end
