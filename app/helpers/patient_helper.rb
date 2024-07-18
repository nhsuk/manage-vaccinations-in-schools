# frozen_string_literal: true

module PatientHelper
  def format_nhs_number(nhs_number)
    nhs_number.to_s.gsub(/(\d{3})(\d{3})(\d{4})/, "\\1 \\2 \\3")
  end
end
