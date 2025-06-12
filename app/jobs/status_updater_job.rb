# frozen_string_literal: true

class StatusUpdaterJob < NotifyDeliveryJob
  queue_as :default

  def perform(patient: nil, session: nil)
    StatusUpdater.call(patient: patient, session: session)
  end
end
