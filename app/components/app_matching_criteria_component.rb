class AppMatchingCriteriaComponent < ViewComponent::Base
  delegate :common_name, :date_of_birth, :age, :parent_name, to: :@consent_form

  def initialize(consent_form:)
    super

    @consent_form = consent_form
  end

  def child_full_name
    @consent_form.full_name
  end

  def address_present?
    address_fields.any?
  end

  def address_fields
    [
      @consent_form.address_line_1,
      @consent_form.address_line_2,
      @consent_form.address_town,
      @consent_form.address_postcode
    ].reject(&:blank?)
  end

  def parent_guardian_or_other
    @consent_form.parent.relationship_label
  end
end
