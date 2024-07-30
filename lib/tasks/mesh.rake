# frozen_string_literal: true

namespace :mesh do
  desc "Export DPS data via MESH"
  task dps_export: :environment do
    DPSExportJob.perform_now
  end

  desc "Check MESH inbox, listing any messages"
  task "check_inbox" => :environment do
    response = MESH.connection.get("inbox")

    puts response.body
    warn response.status unless response.status == 200
  end

  desc "Get message from MESH"
  task "get_message", [:message] => :environment do |_, args|
    message = args[:message]

    response = MESH.connection.get("inbox/#{message}")

    puts response.body
    warn response.status unless response.status == 200
  end

  desc "Acknowledge message MESH, removing it from inbox"
  task "ack_message", [:message] => :environment do |_, args|
    message = args[:message]

    response = MESH.connection.put("inbox/#{message}/status/acknowledged")

    warn response.status unless response.status == 200
  end
end
