# frozen_string_literal: true

class AppConsentPatientSummaryComponent < ViewComponent::Base
  def initialize(consent)
    super

    @consent = consent
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { patient.full_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { patient.date_of_birth.to_fs(:long) }
      end

      if (consent_form = consent.consent_form)
        summary_list.with_row do |row|
          row.with_key { "Home address" }
          row.with_value { helpers.format_address_multi_line(consent_form) }
        end

        summary_list.with_row do |row|
          row.with_key { "GP surgery" }
          row.with_value do
            if consent_form.gp_response_yes?
              consent_form.gp_name
            elsif consent_form.gp_response_no?
              "Not registered"
            elsif consent_form.gp_response_dont_know?
              "Not known"
            end
          end
        end
      end

      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { helpers.patient_school(patient) }
      end
    end
  end

  private

  attr_reader :consent

  delegate :patient, to: :consent
end
