# frozen_string_literal: true

class AppVaccineCriteriaLabelComponent < ViewComponent::Base
  def initialize(vaccine_criteria, programme:, context:)
    @vaccine_criteria = vaccine_criteria
    @programme = programme
    @context = context
  end

  def call
    if data_value
      tag.span(text, class: "app-vaccine-criteria", data: { value: data_value })
    else
      tag.span(text)
    end
  end

  def render? = text.present?

  private

  attr_reader :vaccine_criteria, :programme, :context

  def data_value
    @data_value ||=
      if vaccine_criteria.without_gelatine
        "without-gelatine"
      elsif vaccine_criteria.vaccine_methods.include?("nasal")
        "nasal"
      end
  end

  def text
    @text ||= send("#{context}_text")
  end

  def heading_text
    vaccination =
      if vaccine_criteria.without_gelatine
        "vaccination with gelatine-free injection"
      elsif programme.has_multiple_vaccine_methods?
        vaccine_method = vaccine_criteria.vaccine_methods.first
        method_string =
          Vaccine.human_enum_name(:method, vaccine_method).downcase
        "vaccination with #{method_string}"
      else
        "vaccination"
      end

    "Record #{programme.name_in_sentence} #{vaccination}"
  end

  def vaccine_type_text
    label =
      if vaccine_criteria.without_gelatine
        "Gelatine-free injection"
      elsif programme.has_multiple_vaccine_methods?
        vaccine_method = vaccine_criteria.vaccine_methods.first
        Vaccine.human_enum_name(:method, vaccine_method)
      elsif programme.vaccine_may_contain_gelatine?
        "Either"
      end

    "#{label} for #{programme.name}"
  end
end
