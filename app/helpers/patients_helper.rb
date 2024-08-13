# frozen_string_literal: true

# Replace each space in NHS number with a non-breaking space and
# zero-width word joiner to prevent telephone format detection
module PatientsHelper
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

  def patient_school(patient)
    if (school = patient.school).present?
      school.name
    elsif patient.home_educated
      "Home educated"
    else
      "Unknown school"
    end
  end
end
