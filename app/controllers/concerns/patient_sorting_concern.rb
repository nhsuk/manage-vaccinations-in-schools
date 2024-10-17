# frozen_string_literal: true

module PatientSortingConcern
  extend ActiveSupport::Concern

  def sort_and_filter_patients!(patient_sessions)
    sort_patients!(patient_sessions)
    filter_patients!(patient_sessions)
  end

  def sort_patients!(patient_sessions)
    return if params[:sort].blank?

    case params[:sort]
    when "name"
      patient_sessions.sort_by! { _1.patient.full_name }
    when "outcome"
      patient_sessions.sort_by!(&:state)
    when "year_group"
      patient_sessions.sort_by! do
        [_1.patient.year_group, _1.patient.registration]
      end
    end

    patient_sessions.reverse! if params[:direction] == "desc"
  end

  def filter_patients!(patient_sessions)
    if params[:name].present?
      patient_sessions.select! do
        _1.patient.full_name.downcase.include?(params[:name].downcase)
      end
    end

    if params[:year_groups].present?
      patient_sessions.select! do
        _1.patient.year_group.to_s.in?(params[:year_groups])
      end
    end
  end

  private

  def deep_send(object, method_path)
    method_path.split(".").reduce(object) { |o, m| o.send(m) }
  end
end
