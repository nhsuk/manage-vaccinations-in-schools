# frozen_string_literal: true

class AppPatientDetailsComponent < ViewComponent::Base
  def initialize(session:, patient: nil, consent_form: nil, school: nil)
    super

    unless patient || consent_form
      raise ArgumentError, "patient or consent_form must be provided"
    end

    @session = session
    @object = patient || consent_form
    @school = school
  end

  private

  def known_as
    if @object.respond_to? :common_name
      @object.common_name
    elsif @object.respond_to? :preferred_name
      @object.preferred_name
    end
  end

  def date_of_birth
    if @object.respond_to? :dob
      @object.dob
    else
      @object.date_of_birth
    end
  end

  def aged
    "aged #{date_of_birth ? @object.age : ""}"
  end

  def parent_guardian_or_other
    if @object.parent_relationship == "other"
      @object.human_enum_name(:parent_relationship_other)
    else
      @object.human_enum_name(:parent_relationship)
    end
  end

  def address_present?
    @object.try(:address_line_1).present? ||
      @object.try(:address_line_2).present? ||
      @object.try(:address_town).present? ||
      @object.try(:address_postcode).present?
  end

  def address_formatted
    safe_join(
      [
        @object.address_line_1,
        @object.address_line_2,
        @object.address_town,
        @object.address_postcode
      ].reject(&:blank?),
      tag.br
    )
  end

  def gp_response_present?
    @object.try(:gp_response).present?
  end

  def nhs_number
    @object.nhs_number if @object.respond_to? :nhs_number
  end

  def nhs_number_formatted
    nhs_number.to_s.gsub(/(\d{3})(\d{3})(\d{4})/, "\\1 \\2 \\3")
  end
end
