# frozen_string_literal: true

module PatientsHelper
  # Replace each space in NHS number with a non-breaking space and
  # zero-width word joiner to prevent telephone format detection
  def format_nhs_number(nhs_number)
    if nhs_number.present?
      tag.span(class: "app-u-monospace") do
        nhs_number
          .to_s
          .gsub(/(\d{3})(\d{3})(\d{4})/, "\\1&nbsp;&zwj;\\2&nbsp;&zwj;\\3")
          .html_safe
      end
    else
      "Not provided"
    end
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
      tag.i("Unknown")
    end
  end

  def patient_year_group(patient)
    if (registration = patient.registration).present?
      "#{format_year_group(patient.year_group)} (#{registration})"
    else
      format_year_group(patient.year_group)
    end
  end

  def patient_parents(patient)
    tag.ul(class: "nhsuk-list") do
      safe_join(
        patient.parents.map do |parent|
          tag.li { format_parent(parent, patient:) }
        end
      )
    end
  end
end
