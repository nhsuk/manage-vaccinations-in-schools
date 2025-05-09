# frozen_string_literal: true

module VaccinationsHelper
  def available_delivery_methods_for(object)
    object.available_delivery_methods.map do
      [it, VaccinationRecord.human_enum_name("delivery_methods", it)]
    end
  end

  def available_delivery_sites_for(object)
    object.available_delivery_sites.map do
      [it, VaccinationRecord.human_enum_name("delivery_sites", it)]
    end
  end
end
