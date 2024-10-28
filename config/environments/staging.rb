# frozen_string_literal: true

require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.good_job.enable_cron = true
  config.good_job.cron = {
    bulk_update_patients_from_pds: {
      cron: "every day at 00:00 and 6:00 and 12:00 and 18:00",
      class: "BulkUpdatePatientsFromPDSJob",
      description: "Keep patient details up to date with PDS."
    },
    mesh_validate_mailbox: {
      cron: "every day at 1am",
      class: "MESHValidateMailboxJob",
      description: "Validate MESH mailbox"
    },
    mesh_dps_export: {
      cron: "every day at 2am",
      class: "MESHDPSExportJob",
      description: "Export DPS data via MESH"
    },
    mesh_track_dps_exports: {
      cron: "every day at 3am",
      class: "MESHTrackDPSExportsJob",
      description: "Track the status of DPS exports"
    },
    remove_import_csv: {
      cron: "every day at 1am",
      class: "RemoveImportCSVJob",
      description: "Remove CSV data from old cohort and immunisation imports"
    }
  }
end
