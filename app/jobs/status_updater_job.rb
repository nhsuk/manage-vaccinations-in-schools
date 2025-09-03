# frozen_string_literal: true

class StatusUpdaterJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :statuses

  good_job_control_concurrency_with perform_limit: 1

  def perform(patient: nil, session: nil)
    StatusUpdater.call(patient: patient, session: session)
  end
end
