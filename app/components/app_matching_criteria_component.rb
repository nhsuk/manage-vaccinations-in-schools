# frozen_string_literal: true

class AppMatchingCriteriaComponent < ViewComponent::Base
  delegate :common_name, :date_of_birth, :age, to: :@consent_form

  def initialize(consent_form:)
    super

    @consent_form = consent_form
  end

  def parent_name
    @consent_form.parent_name
  end

  def child_full_name
    @consent_form.full_name
  end

  def address_present?
    address_parts.any?
  end

  def address_parts
    @consent_form.address_parts
  end

  def parent_guardian_or_other
    @consent_form.parent_relationship_label
  end
end
