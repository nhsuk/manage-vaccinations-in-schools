#!/usr/bin/env ruby

# frozen_string_literal: true

desc "Acknowledge message MESH, removing it from inbox"
task "mesh:ack_message", [:message] => :environment do |_, args|
  message = args[:message]

  response = MESH.connection.put("inbox/#{message}/status/acknowledged")

  warn response.status unless response.status == 200
end
