# frozen_string_literal: true

class Programme::PatientsController < ApplicationController
  include Pagy::Backend

  before_action :set_programme

  def index
    @pagy, @patients = pagy(@programme.patients.not_deceased.order_by_name)

    render layout: "full"
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
