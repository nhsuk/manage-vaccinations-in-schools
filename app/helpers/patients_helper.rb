# frozen_string_literal: true

module PatientsHelper
  def format_nhs_number(nhs_number)
    if nhs_number.present?
      tag.span(class: "app-u-monospace") do
        nhs_number.to_s.gsub(/(\d{3})(\d{3})(\d{4})/, "\\1 \\2 \\3")
      end
    else
      "Not provided"
    end
  end
end
