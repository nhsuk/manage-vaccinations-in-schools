# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_organisation

  skip_after_action :verify_policy_scoped

  def index
    render layout: "full"
  end

  def create
    DraftImport.new(request_session: session, current_user:).reset!
    redirect_to draft_import_path(Wicked::FIRST_STEP)
  end

  private

  def set_organisation
    @organisation = current_organisation
  end
end
