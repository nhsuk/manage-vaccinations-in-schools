# frozen_string_literal: true

class Users::OrganisationsController < ApplicationController
  skip_before_action :set_selected_organisation
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled
  before_action :set_organisations

  layout "two_thirds"

  def new
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
          "workgroups" => [User::CIS2_WORKGROUP]
        }
      }

      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end

  def set_organisations
    @organisations = current_user.organisations
  end
end
