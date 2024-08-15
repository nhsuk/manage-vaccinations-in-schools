# frozen_string_literal: true

class DPSExportJob < ApplicationJob
  queue_as :default

  def perform
    campaign = Campaign.active.first # TODO: Not .first
    data = DPSExport.create!(campaign:).export!
    MESH.send_file(data:, to: Settings.mesh.dps_mailbox)
  end
end
