# frozen_string_literal: true

class StatusUpdaterJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :cache

  def perform(patient: nil, session: nil)
    StatusUpdater.call(patient:, session:)
  end
end
