# frozen_string_literal: true

class PatientsController < ApplicationController
  include Pagy::Backend

  layout "full"

  def index
    @pagy, @patients = pagy(policy_scope(Patient).order_by_name)
  end
end
