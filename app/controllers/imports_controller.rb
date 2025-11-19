# frozen_string_literal: true

class ImportsController < ApplicationController
  skip_after_action :verify_policy_scoped
  helper_method :uploaded_files_view?

  def index
    @active = :uploaded
    render layout: "full"
  end

  def records
    @active = :imported
    render :index, layout: "full"
  end

  def create
    DraftImport.new(request_session: session, current_user:).clear!
    redirect_to draft_import_path(Wicked::FIRST_STEP)
  end

  private

  def uploaded_files_view?
    @active == :uploaded
  end
end
