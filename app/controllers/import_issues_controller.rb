# frozen_string_literal: true

class ImportIssuesController < ApplicationController
  before_action :set_programme

  def index
    @import_issues = @programme.import_issues

    render layout: "full"
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme)
        .active
        .includes(:immunisation_imports)
        .find(params[:programme_id])
  end
end
