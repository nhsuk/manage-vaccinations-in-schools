# frozen_string_literal: true

class CohortsController < ApplicationController
  before_action :set_programme

  def index
    @patients = @programme.patients.recorded

    render layout: "full"
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme).includes(:patients).find(params[:programme_id])
  end
end
