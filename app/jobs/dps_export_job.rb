# frozen_string_literal: true

class DPSExportJob < ApplicationJob
  queue_as :default

  def perform
    data = DPSExport.new(campaigns: Campaign.all).export!
    MESH.send_file(data:, to: Settings.mesh.dps_mailbox)
  end
end
