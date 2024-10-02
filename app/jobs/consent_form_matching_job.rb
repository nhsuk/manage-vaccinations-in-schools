# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  queue_as :default

  def perform(consent_form)
    patient = consent_form.find_matching_patient

    return unless patient

    Consent.from_consent_form!(consent_form, patient:)
  end
end
