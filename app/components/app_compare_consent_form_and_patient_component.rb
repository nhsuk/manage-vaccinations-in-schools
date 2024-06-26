# frozen_string_literal: true

class AppCompareConsentFormAndPatientComponent < ViewComponent::Base
  attr_reader :heading, :consent_form, :patient

  def initialize(heading:, consent_form:, patient:)
    super

    @heading = heading
    @consent_form = consent_form
    @patient = patient
  end

  def name_match?
    consent_form.full_name == patient.full_name
  end

  def date_of_birth_match?
    consent_form.date_of_birth == patient.date_of_birth
  end

  def address_match?
    consent_form.address_fields == patient.address_fields
  end

  def mark(text, opts)
    if !opts[:unless] && !opts[:if]
      tag.span(class: "nhsuk-u-visually-hidden") { "Inconsistent: " } +
        tag.mark(text)
    else
      text
    end
  end
end
