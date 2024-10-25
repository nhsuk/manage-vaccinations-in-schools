# frozen_string_literal: true

module PatientSortingConcern
  extend ActiveSupport::Concern

  def sort_and_filter_patients!(patients_or_patient_sessions)
    sort_patients!(patients_or_patient_sessions)
    filter_patients!(patients_or_patient_sessions)
  end

  def sort_patients!(patients_or_patient_sessions)
    key = params[:sort]
    return if key.blank?

    patients_or_patient_sessions.sort_by! do |patient_or_patient_session|
      sort_by_value(patient_or_patient_session, key)
    end

    patients_or_patient_sessions.reverse! if params[:direction] == "desc"
  end

  def sort_by_value(obj, key)
    case key
    when "dob"
      obj.try(:date_of_birth) || obj.patient.date_of_birth
    when "name"
      obj.try(:full_name) || obj.patient.full_name
    when "outcome"
      obj.state
    when "postcode"
      obj.try(:address_postcode) || obj.patient.address_postcode
    when "year_group"
      [
        obj.try(:year_group) || obj.patient.year_group,
        obj.try(:registration) || obj.patient.registration
      ]
    end
  end

  def filter_patients!(patients_or_patient_sessions)
    if (name = params[:name]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:full_name) || _1.patient.full_name
        value.downcase.include?(name.downcase)
      end
    end

    if (postcode = params[:postcode]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:address_postcode) || _1.patient.address_postcode
        value&.downcase&.include?(postcode.downcase)
      end
    end

    if (year_groups = params[:year_groups]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:year_group) || _1.patient.year_group
        value.to_s.in?(year_groups)
      end
    end
  end
end
