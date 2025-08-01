# frozen_string_literal: true

class Users::OrganisationsController < ApplicationController
  skip_before_action :set_selected_organisation
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled

  layout "two_thirds"

  def new
    @form = SelectOrganisationForm.new(current_user:)
  end

  def create
    @form =
      SelectOrganisationForm.new(
        current_user:,
        request_session: session,
        organisation_id: params.dig(:select_organisation_form, :organisation_id)
      )

    if @form.save
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end
end
