# frozen_string_literal: true

class DPSExportJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled? :mesh_jobs

    Campaign.active.find_each do |campaign|
      if campaign.vaccination_records.recorded.administered.unexported.any?
        dps_export = DPSExport.create!(campaign:)
        response =
          MESH.send_file(data: dps_export.csv, to: Settings.mesh.dps_mailbox)

        if response.success?
          mesh_reply = JSON.parse(response.body)
          message_id = mesh_reply.fetch("message_id")
          dps_export.update!(status: "sent", message_id:)

          Rails.logger.info(
            "DPS export (#{dps_export.id}) for campaign (#{campaign.id}) sent: " \
              "#{response.status} - #{response.body}"
          )
        else
          dps_export.update!(status: "failed")
          Rails.logger.error(
            "DPS export (#{dps_export.id}) for campaign (#{campaign.id}) send failed: " \
              " #{response.status} - #{response.body}"
          )
        end
      else
        Rails.logger.info(
          "No vaccination records to export for campaign #{campaign.id}"
        )
      end
    end
  end
end
