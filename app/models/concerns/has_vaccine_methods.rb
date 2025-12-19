# frozen_string_literal: true

module HasVaccineMethods
  extend ActiveSupport::Concern

  included do
    extend ArrayEnum

    array_enum vaccine_methods: { injection: 0, nasal: 1 }

    validates :vaccine_methods, subset: vaccine_methods.keys
  end

  def vaccine_method_injection? = vaccine_methods.include?("injection")

  def vaccine_method_nasal? = vaccine_methods.include?("nasal")

  def vaccine_method_nasal_only? = vaccine_methods == %w[nasal]

  def vaccine_method_injection_and_nasal?
    vaccine_method_injection? && vaccine_method_nasal?
  end
end
