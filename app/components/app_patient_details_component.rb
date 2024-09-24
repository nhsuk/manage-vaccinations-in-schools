# frozen_string_literal: true

class AppPatientDetailsComponent < ViewComponent::Base
  def initialize(patient: nil, consent_form: nil)
    super

    unless patient || consent_form
      raise ArgumentError, "patient or consent_form must be provided"
    end

    @object = patient || consent_form
    @school = patient&.school
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { @object.full_name }
      end

      if @object.common_name.present?
        summary_list.with_row do |row|
          row.with_key { "Known as" }
          row.with_value { @object.common_name }
        end
      end

      if @object.date_of_birth.present?
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { "#{@object.date_of_birth.to_fs(:long)} (#{aged})" }
        end
      end

      if address_present?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { helpers.format_address_multi_line(@object) }
        end
      end

      if @school.present?
        summary_list.with_row do |row|
          row.with_key { "School" }
          row.with_value { @school.name }
        end
      end

      if gp_response_present?
        if @object.gp_response_yes?
          summary_list.with_row do |row|
            row.with_key { "GP" }
            row.with_value { @object.gp_name }
          end
        else
          summary_list.with_row do |row|
            row.with_key { "Registered with a GP" }
            row.with_value { @object.gp_response_no? ? "No" : "I don’t know" }
          end
        end
      end

      summary_list.with_row do |row|
        row.with_key { "NHS number" }
        row.with_value { helpers.format_nhs_number(nhs_number) }
      end

      if parent_or_guardians.present?
        summary_list.with_row do |row|
          row.with_key { "Parent or guardian" }
          row.with_value { parent_or_guardians_formatted }
        end
      end
    end
  end

  private

  def aged
    "aged #{@object.date_of_birth ? @object.age : ""}"
  end

  def parent_guardian_or_other
    @object&.parent&.relationship_label
  end

  def address_present?
    @object.try(:address_line_1).present? ||
      @object.try(:address_line_2).present? ||
      @object.try(:address_town).present? ||
      @object.try(:address_postcode).present?
  end

  def gp_response_present?
    @object.try(:gp_response).present?
  end

  def nhs_number
    @object.try(:nhs_number)
  end

  def parent_or_guardians
    @parent_or_guardians ||=
      if @object.is_a?(ConsentForm)
        [
          {
            name: @object.parent_name,
            relationship: @object.parent_relationship_label,
            phone: @object.parent_phone
          }
        ]
      else
        @object.parent_relationships.map do |parent_relationship|
          {
            name: parent_relationship.parent.name,
            relationship: parent_relationship.label,
            phone: parent_relationship.parent.phone
          }
        end
      end
  end

  def parent_or_guardians_formatted
    tag.ul(class: "nhsuk-list") do
      safe_join(
        parent_or_guardians.map do |parent_or_guardian|
          tag.li do
            [
              "#{parent_or_guardian[:name]} (#{parent_or_guardian[:relationship]})",
              if (phone = parent_or_guardian[:phone]).present?
                tag.span(phone, class: "nhsuk-u-secondary-text-color")
              end
            ].compact.join(tag.br).html_safe
          end
        end
      )
    end
  end
end
