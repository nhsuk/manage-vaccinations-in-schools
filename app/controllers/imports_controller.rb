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
    if params[:type] == "class-list"
      DraftClassImport.new(request_session: session, current_user:).reset!
      redirect_to draft_class_import_path(Wicked::FIRST_STEP)
    else
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
  end

  private

  def set_organisation
    @organisation = current_organisation
  end
end
