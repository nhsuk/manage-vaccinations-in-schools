# frozen_string_literal: true

class Users::OrganisationsController < ApplicationController
  skip_before_action :set_selected_organisation
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled

  layout "two_thirds"

  def new
    @organisations = current_user.organisations
  end

  def create
    organisation = current_user.organisations.find(params[:organisation_id])

    if organisation.present?
      session["cis2_info"] = {
        "selected_org" => {
          "name" => organisation.name,
          "code" => organisation.ods_code
        },
        "selected_role" => {
          "code" => valid_cis2_roles.first,
          "workgroups" => ["schoolagedimmunisations"]
        }
      }

      redirect_after_choosing_org
    else
      @organisations = current_user.organisations
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end

  def redirect_after_choosing_org
    url = after_sign_in_path_for(current_user)
    session.delete(:redirect_after_login)
    redirect_to url
  end
end
