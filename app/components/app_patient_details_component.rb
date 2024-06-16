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
          row.with_value do
            "#{@object.date_of_birth.to_fs(:nhsuk_date)} (#{aged})"
          end
        end
      end

      if address_present?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { address_formatted }
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

      if nhs_number.present?
        summary_list.with_row do |row|
          row.with_key { "NHS Number" }
          row.with_value { nhs_number_formatted }
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
