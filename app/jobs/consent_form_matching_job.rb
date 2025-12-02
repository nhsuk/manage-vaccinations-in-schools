# frozen_string_literal: true

class ConsentFormMatchingJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :consents

  def perform(...) = ProcessConsentFormJob.new.perform(...)
end
