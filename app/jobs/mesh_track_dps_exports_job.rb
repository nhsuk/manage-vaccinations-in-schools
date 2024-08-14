# frozen_string_literal: true

class MESHTrackDPSExportsJob < ApplicationJob
  queue_as :mesh

  def perform
    return unless Flipper.enabled?(:mesh_jobs)

    exports = DPSExport.where(status: "accepted")
    exports.each do |export|
      response = MESH.track_message(export.message_id)
      result = JSON.parse(response.body)
      if result["status"] == "acknowledged"
        export.update! status: "acknowledged"
      end
    end
  end
end
