# frozen_string_literal: true

class StatusUpdaterJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :statuses

  def perform(patient: nil, session: nil)
    StatusUpdater.call(patient: patient, session: session)
  end
end
