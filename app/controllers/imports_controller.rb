# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_organisation

  skip_after_action :verify_policy_scoped

  def index
    render layout: "full"
  end

  def new
  end

  def create
    redirect_to(
      if params[:type] == "vaccinations"
        new_immunisation_import_path
      elsif params[:type] == "children"
        new_cohort_import_path
      else
        new_import_path
      end
    )
  end

  private

  def set_organisation
    @organisation = current_user.selected_organisation
  end
end
