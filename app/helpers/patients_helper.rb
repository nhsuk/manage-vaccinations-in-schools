# frozen_string_literal: true

module PatientsHelper
  # Replace each space in NHS number with a non-breaking space and
  # zero-width word joiner to prevent telephone format detection
  def patient_nhs_number(patient)
    span =
      if patient.nhs_number.blank?
        "Not provided"
      else
        tag.span(class: "app-u-monospace") do
          patient
            .nhs_number
            .to_s
            .gsub(/(\d{3})(\d{3})(\d{4})/, "\\1&nbsp;&zwj;\\2&nbsp;&zwj;\\3")
            .html_safe
        end
      end

    patient.try(:invalidated?) ? tag.s(span) : span
  end

  def patient_date_of_birth(patient)
    "#{patient.date_of_birth.to_fs(:long)} (aged #{patient.age})"
  end

  def patient_school(patient)
    if (school = patient.school).present?
      school.name
    elsif patient.home_educated
      "Home-schooled"
    else
      "Unknown school"
    end
  end

  def patient_year_group(patient, academic_year:)
    parts = [
      format_year_group(patient.year_group(academic_year:)),
      if patient.registration_academic_year == academic_year &&
           patient.registration.present?
        "(#{patient.registration})"
      end,
      if academic_year != AcademicYear.current
        "(#{format_academic_year(academic_year)} academic year)"
      end
    ]

    parts.compact.join(" ")
  end

  def patient_parents(patient)
    format_parents_with_relationships(patient.parent_relationships)
  end
end
