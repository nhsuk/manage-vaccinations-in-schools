# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :set_programme

  def index
    @immunisation_imports =
      @programme
        .immunisation_imports
        .recorded
        .includes(:uploaded_by)
        .order(:created_at)
        .strict_loading

    render layout: "full"
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:programme_id])
  end
end
