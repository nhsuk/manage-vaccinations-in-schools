# frozen_string_literal: true

class AppCompareConsentFormAndPatientComponent < ViewComponent::Base
  attr_reader :heading, :consent_form, :patient

  def initialize(heading:, consent_form:, patient:)
    super

    @heading = heading
    @consent_form = consent_form
    @patient = patient
  end

  def full_name_match?
    consent_form.full_name == patient.full_name
  end

  def preferred_full_name_match?
    consent_form.preferred_full_name == patient.preferred_full_name
  end

  def date_of_birth_match?
    consent_form.date_of_birth == patient.date_of_birth
  end

  def address_match?
    consent_form.address_parts == patient.address_parts
  end

  def school_match?
    consent_form.home_educated == patient.home_educated &&
      consent_form.school == patient.school
  end

  def consent_form_patient
    parent =
      Parent.new(
        full_name: consent_form.parent_full_name,
        email: consent_form.parent_email,
        phone: consent_form.parent_phone
      )

    parent_relationship =
      ParentRelationship.new(
        parent:,
        type: consent_form.parent_relationship_type,
        other_name: consent_form.parent_relationship_other_name
      )

    Patient.new(
      school: consent_form.school,
      home_educated: consent_form.home_educated,
      parent_relationships: [parent_relationship]
    )
  end

  def mark(text, opts)
    opts[:unless] ? text : tag.mark(text, class: "app-highlight")
  end
end
