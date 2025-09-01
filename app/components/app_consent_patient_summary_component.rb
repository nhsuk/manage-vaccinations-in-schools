# frozen_string_literal: true

class AppConsentPatientSummaryComponent < ViewComponent::Base
  def initialize(consent)
    @consent = consent
  end

  def call
    govuk_summary_list do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { consent_form_or_patient.full_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { consent_form_or_patient.date_of_birth.to_fs(:long) }
      end

      unless restricted?
        summary_list.with_row do |row|
          row.with_key { "Home address" }
          row.with_value do
            helpers.format_address_multi_line(consent_form_or_patient)
          end
        end
      end

      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { helpers.patient_school(consent_form_or_patient) }
      end
    end
  end

  private

  def consent_form_or_patient
    @consent.consent_form || @consent.patient
  end

  def restricted?
    @consent.patient.restricted?
  end
end
