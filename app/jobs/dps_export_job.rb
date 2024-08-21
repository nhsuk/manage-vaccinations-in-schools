# frozen_string_literal: true

class DPSExportJob < ApplicationJob
  queue_as :default

  def perform
    Campaign.active.find_each do |campaign|
      if campaign.vaccination_records.recorded.administered.unexported.any?
        data = DPSExport.create!(campaign:).csv
        MESH.send_file(data:, to: Settings.mesh.dps_mailbox)
      end
    end
  end
end
