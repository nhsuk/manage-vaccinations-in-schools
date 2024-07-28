# frozen_string_literal: true

desc "Export DPS data via MESH"
task dps_mesh_export: :environment do
  DPSExportJob.perform_now
end
