# frozen_string_literal: true

module VaccinesHelper
  def vaccine_heading(vaccine)
    "#{vaccine.brand} (#{vaccine.programme.name})"
  end

  def vaccine_delivery_methods(vaccine)
    vaccine.available_delivery_methods.map do |m|
      [m, VaccinationRecord.human_enum_name("delivery_methods", m)]
    end
  end

  def vaccine_delivery_sites(vaccine)
    vaccine.available_delivery_sites.map do |s|
      [s, VaccinationRecord.human_enum_name("delivery_sites", s)]
    end
  end
end
