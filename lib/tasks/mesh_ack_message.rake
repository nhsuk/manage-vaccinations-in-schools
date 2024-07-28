#!/usr/bin/env ruby

# frozen_string_literal: true

desc "Acknowledge message MESH, removing it from inbox"
task "mesh:ack_message", [:message] => :environment do |_, args|
  message = args[:message]
  base_url = Settings.mesh.base_url
  mailbox = Settings.mesh.mailbox
  authorisation = MESH.generate_authorisation

  headers = {
    "Accept" => "application/vnd.mesh.v2+json",
    "Authorization" => "#{MESH::SCHEMA} #{authorisation}"
  }

  conn =
    Faraday.new do |faraday|
      faraday.ssl[:verify] = false if Rails.env.development?
      faraday.headers = headers
    end

  response =
    conn.put(
      "#{base_url}/messageexchange/#{mailbox}/inbox/#{message}/status/acknowledged"
    )
  warn response.status unless response.status == 200
end
