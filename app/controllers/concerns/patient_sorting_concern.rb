# frozen_string_literal: true

module PatientSortingConcern
  extend ActiveSupport::Concern

  def sort_and_filter_patients!(patients_or_patient_sessions, programme: nil)
    sort_patients!(patients_or_patient_sessions, programme:)
    filter_patients!(patients_or_patient_sessions, programme:)
  end

  def sort_patients!(patients_or_patient_sessions, programme:)
    key = params[:sort]
    return if key.blank?

    patients_or_patient_sessions.sort_by! do |patient_or_patient_session|
      sort_by_value(patient_or_patient_session, key, programme:)
    end

    patients_or_patient_sessions.reverse! if params[:direction] == "desc"
  end

  def sort_by_value(obj, key, programme:)
    case key
    when "dob"
      obj.try(:date_of_birth) || obj.patient.date_of_birth
    when "name"
      obj.try(:full_name) || obj.patient.full_name
    when "status"
      obj.try(:status, programme:) || "not_in_session"
    when "postcode"
      patient = obj.is_a?(Patient) ? obj : obj.patient

      patient.restricted? ? "" : patient.address_postcode || ""
    when "year_group"
      [
        obj.try(:year_group) || obj.patient.year_group || "",
        (
          if obj.respond_to?(:registration)
            obj.registration
          else
            obj.patient.registration
          end
        ) || ""
      ]
    end
  end

  def filter_patients!(patients_or_patient_sessions, programme:)
    if (name = params[:name]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:full_name) || _1.patient.full_name
        value.downcase.include?(name.downcase)
      end
    end

    if (postcode = params[:postcode]).present?
      patients_or_patient_sessions.select! do |obj|
        patient = obj.is_a?(Patient) ? obj : obj.patient

        next false if patient.restricted?

        patient.address_postcode&.downcase&.include?(postcode.downcase)
      end
    end

    if (date_of_birth = params[:dob]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:date_of_birth) || _1.patient.date_of_birth
        value.to_fs(:uk_short).include?(date_of_birth)
      end
    end

    if (year_groups = params[:year_groups]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:year_group) || _1.patient.year_group
        value.to_s.in?(year_groups)
      end
    end

    if (statuses = params[:status]).present?
      patients_or_patient_sessions.select! do
        value = _1.try(:status, programme:) || "not_in_session"
        t("patient_session_statuses.#{value}.banner_title").in?(statuses)
      end
    end
  end
end
