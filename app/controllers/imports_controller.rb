# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :authorize_import
  skip_after_action :verify_policy_scoped

  helper_method :uploaded_files_view?

  layout "full"

  def index
    @active = :uploaded
  end

  def records
    @active = :imported
    render :index
  end

  def create
    if current_team.has_national_reporting_access?
      redirect_to new_immunisation_import_path
    else
      DraftImport.new(request_session: session, current_user:).clear!
      redirect_to draft_import_path(Wicked::FIRST_STEP)
    end
  end

  private

  def authorize_import
    authorize :import
  end

  def uploaded_files_view?
    @active == :uploaded
  end
end
