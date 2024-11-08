# frozen_string_literal: true

class MESHDPSExportJob < ApplicationJob
  queue_as :mesh

  def perform
    return unless Flipper.enabled? :mesh_jobs

    Programme.find_each do |programme|
      if programme.vaccination_records.administered.unexported.any?
        dps_export = DPSExport.create!(programme:)
        response =
          MESH.send_file(data: dps_export.csv, to: Settings.mesh.dps_mailbox)

        if response.success?
          mesh_reply = JSON.parse(response.body)
          message_id = mesh_reply.fetch("message_id")
          dps_export.update!(status: "accepted", message_id:)

          Rails.logger.info(
            "DPS export (#{dps_export.id}) for programme (#{programme.id}) sent: " \
              "#{response.status} - #{response.body}"
          )
        else
          dps_export.update!(status: "failed")
          Rails.logger.error(
            "DPS export (#{dps_export.id}) for programme (#{programme.id}) send failed: " \
              " #{response.status} - #{response.body}"
          )
        end
      else
        Rails.logger.info(
          "No vaccination records to export for programme #{programme.id}"
        )
      end
    end
  end
end
