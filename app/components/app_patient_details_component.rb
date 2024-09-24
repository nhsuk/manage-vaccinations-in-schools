# frozen_string_literal: true

class AppPatientDetailsComponent < ViewComponent::Base
  def initialize(patient)
    super

    @patient = patient
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { @patient.full_name }
      end

      if @patient.common_name.present?
        summary_list.with_row do |row|
          row.with_key { "Known as" }
          row.with_value { @patient.common_name }
        end
      end

      if @patient.date_of_birth.present?
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value do
            "#{@patient.date_of_birth.to_fs(:long)} (aged #{@patient.age})"
          end
        end
      end

      if @patient.has_address?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { helpers.format_address_multi_line(@patient) }
        end
      end

      if (school = @patient.school).present?
        summary_list.with_row do |row|
          row.with_key { "School" }
          row.with_value { school.name }
        end
      end

      if (nhs_number = @patient.nhs_number).present?
        summary_list.with_row do |row|
          row.with_key { "NHS number" }
          row.with_value { helpers.format_nhs_number(nhs_number) }
        end
      end

      if @patient.parent_relationships.present?
        summary_list.with_row do |row|
          row.with_key { "Parent or guardian" }
          row.with_value { parent_or_guardians_formatted }
        end
      end
    end
  end

  private

  def parent_or_guardians_formatted
    tag.ul(class: "nhsuk-list") do
      safe_join(
        @patient.parent_relationships.map do |parent_relationship|
          tag.li do
            [
              "#{parent_relationship.parent.name} (#{parent_relationship.label})",
              if (phone = parent_relationship.parent.phone).present?
                tag.span(phone, class: "nhsuk-u-secondary-text-color")
              end
            ].compact.join(tag.br).html_safe
          end
        end
      )
    end
  end
end
