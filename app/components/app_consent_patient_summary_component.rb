# frozen_string_literal: true

class AppConsentPatientSummaryComponent < ViewComponent::Base
  def initialize(consent)
    super

    @consent = consent
  end

  def call
    govuk_summary_list do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { patient.full_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { patient.date_of_birth.to_fs(:long) }
      end

      if !consent.restricted? && (consent_form = consent.consent_form)
        summary_list.with_row do |row|
          row.with_key { "Home address" }
          row.with_value { helpers.format_address_multi_line(consent_form) }
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
