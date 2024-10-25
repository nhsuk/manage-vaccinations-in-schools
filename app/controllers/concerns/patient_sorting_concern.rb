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
    when "dob"
      patient_sessions.sort_by! { _1.patient.date_of_birth }
    when "name"
      patient_sessions.sort_by! { _1.patient.full_name }
    when "outcome"
      patient_sessions.sort_by!(&:state)
    when "postcode"
      patient_sessions.sort_by! { _1.patient.address_postcode }
    when "year_group"
      patient_sessions.sort_by! do
        [_1.patient.year_group, _1.patient.registration]
      end
    end

    patient_sessions.reverse! if params[:direction] == "desc"
  end

  def filter_patients!(patient_sessions)
    if (name = params[:name]).present?
      patient_sessions.select! do
        _1.patient.full_name.downcase.include?(name.downcase)
      end
    end

    if (postcode = params[:postcode]).present?
      patient_sessions.select! do
        _1.patient.address_postcode&.downcase&.include?(postcode.downcase)
      end
    end

    if (year_groups = params[:year_groups]).present?
      patient_sessions.select! { _1.patient.year_group.to_s.in?(year_groups) }
    end
  end
end
