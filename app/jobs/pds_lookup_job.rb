# frozen_string_literal: true

class PDSLookupJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :pds

  # NHS API imposes a limit of 5 requests per second
  good_job_control_concurrency_with perform_limit: 5,
                                    perform_throttle: [5, 1.second],
                                    key: -> { queue_name }

  # Because the NHS API imposes a limit of 5 requests per second, we're almost
  # certain to hit throttling and the default exponential backoff strategy
  # appears to trigger more race conditions in the job performing code, meaning
  # there’s more instances where more than 5 requests are attempted.
  retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
           attempts: :unlimited,
           wait: ->(_) { rand(0.5..5) }

  def perform(patient)
    return if patient.nhs_number.present?

    params = {
      "family" => patient.family_name,
      "given" => patient.given_name,
      "birthdate" => "eq#{patient.date_of_birth}",
      "address-postalcode" => patient.address_postcode,
      "_history" => true # look up previous names and addresses,
    }.compact_blank

    response = NHS::PDS::Patient.find_by(**params)
    results = response.body

    return if results["total"].zero?

    entry = results["entry"].first
    nhs_number = entry["resource"]["id"]

    patient.update!(nhs_number:)
  end
end
