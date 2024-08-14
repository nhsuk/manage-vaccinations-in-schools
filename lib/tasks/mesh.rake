# frozen_string_literal: true

namespace :mesh do
  desc "Export DPS data via MESH"
  task "dps_export" => :environment do
    Rails.logger = Logger.new($stdout)
    Rails.logger.level = Logger::DEBUG
    DPSExportJob.perform_now
  end

  desc "Validate MESH mailbox to let MESH know Mavis is up and running"
  task validate_mailbox: :environment do
    response = MESH.validate_mailbox
    warn response.status unless response.status == 200
    puts response.headers
    puts response.body
  end

  desc "Track message sent via MESH"
  task "track_message", [:message_id] => :environment do |_, args|
    message_id = args[:message_id]
    response = MESH.track_message(message_id)

    warn response.status unless response.status == 200
    if $stdout.tty? && response.body.present?
      puts JSON.pretty_generate(JSON.parse(response.body))
    else
      puts response.body
    end
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

    puts response.body
    warn response.status unless response.status == 200
  end

  desc "Send a file to a mailbox via MESH"
  task "send_file", %i[to file] => :environment do |_, args|
    to = args[:to]
    file = args[:file]

    data = File.read(file)
    response = MESH.send_file(to:, data:)

    puts response.body
    warn response.status unless response.status == 200
  end
end
