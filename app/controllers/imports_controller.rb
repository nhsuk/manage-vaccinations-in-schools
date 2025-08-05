# frozen_string_literal: true

class ImportsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def index
    render layout: "full"
  end

  def create
    DraftImport.new(request_session: session, current_user:).reset!
    redirect_to draft_import_path(Wicked::FIRST_STEP)
  end
end
