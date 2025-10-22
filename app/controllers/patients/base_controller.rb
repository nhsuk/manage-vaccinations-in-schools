# frozen_string_literal: true

class Patients::BaseController < ApplicationController
  include PatientLoggingConcern
  before_action :set_patient

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id] || params[:id])
  end

  def patient_id_for_logging
    params[:patient_id] || params[:id]
  end
end
