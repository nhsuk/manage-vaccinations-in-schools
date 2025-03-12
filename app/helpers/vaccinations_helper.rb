# frozen_string_literal: true

module VaccinationsHelper
  def vaccination_delivery_methods_for(vaccine)
    vaccine.available_delivery_methods.map do |m|
      [m, VaccinationRecord.human_enum_name("delivery_methods", m)]
    end
  end

  def vaccination_delivery_sites_for(vaccine)
    vaccine.available_delivery_sites.map do |s|
      [s, VaccinationRecord.human_enum_name("delivery_sites", s)]
    end
  end
end
