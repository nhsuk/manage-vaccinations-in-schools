# frozen_string_literal: true

require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.good_job.cron.merge!(
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
    }
  )

  config.action_mailer.notify_settings = {
    api_key: Settings.govuk_notify["#{Settings.govuk_notify.mode}_key"]
  }
end
