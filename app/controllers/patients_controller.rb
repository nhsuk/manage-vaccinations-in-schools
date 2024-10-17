# frozen_string_literal: true

class PatientsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @patients = pagy(policy_scope(Patient).order_by_name)

    render layout: "full"
  end

  def show
    @patient = policy_scope(Patient).find(params[:id])
  end
end
