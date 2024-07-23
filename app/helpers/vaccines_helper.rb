# frozen_string_literal: true

module VaccinesHelper
  def vaccine_heading(vaccine)
    sprintf("%s (%s)", vaccine.brand, t(vaccine.type, scope: "vaccines"))
  end

  def vaccine_dose(vaccine)
    "#{vaccine.human_enum_name(:dose)} ml"
  end
end
