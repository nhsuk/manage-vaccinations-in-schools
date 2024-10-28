# frozen_string_literal: true

class AppMatchingCriteriaComponent < ViewComponent::Base
  delegate :preferred_full_name,
           :has_preferred_name?,
           :date_of_birth,
           :age,
           to: :@consent_form

  def initialize(consent_form:)
    super

    @consent_form = consent_form
  end

  def parent_full_name
    @consent_form.parent_full_name
  end

  def child_full_name
    @consent_form.full_name
  end

  def address_present?
    @consent_form.has_address?
  end

  def address
    helpers.format_address_single_line(@consent_form)
  end

  def parent_guardian_or_other
    @consent_form.parent_relationship_label
  end
end
