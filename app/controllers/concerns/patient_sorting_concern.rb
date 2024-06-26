# frozen_string_literal: true

module PatientSortingConcern
  extend ActiveSupport::Concern

  SORT_MAPPING = {
    "name" => "patient.full_name",
    "dob" => "patient.date_of_birth",
    "outcome" => "state"
  }.freeze

  def sort_and_filter_patients!(patient_sessions)
    sort_patients!(patient_sessions)
    filter_patients!(patient_sessions)
  end

  def sort_patients!(patient_sessions)
    return if params[:sort].blank?

    method_path = SORT_MAPPING[params[:sort]]
    patient_sessions.sort_by! { deep_send(_1, method_path) }
    patient_sessions.reverse! if params[:direction] == "desc"
  end

  def filter_patients!(patient_sessions)
    if params[:name].present?
      patient_sessions.select! do
        _1.patient.full_name.downcase.include?(params[:name].downcase)
      end
    end

    if params[:dob].present?
      patient_sessions.select! do
        _1.patient.date_of_birth.strftime("%d/%m/%Y").include?(params[:dob])
      end
    end
  end

  private

  def deep_send(object, method_path)
    method_path.split(".").reduce(object) { |o, m| o.send(m) }
  end
end
