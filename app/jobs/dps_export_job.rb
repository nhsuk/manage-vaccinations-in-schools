# frozen_string_literal: true

class DPSExportJob < ApplicationJob
  queue_as :default

  def perform
    dps_export =
      DPSExport.new(
        VaccinationRecord.recorded.where(exported_to_dps_at: nil)
      ).export_csv

    MESH.send_file(data: dps_export, to: Settings.mesh.dps_mailbox)
  end
end
