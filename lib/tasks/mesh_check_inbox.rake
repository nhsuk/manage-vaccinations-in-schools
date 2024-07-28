# frozen_string_literal: true

desc "Check MESH inbox, listing any messages"
task "mesh:check_inbox" => :environment do
  base_url = Settings.mesh.base_url
  mailbox = Settings.mesh.mailbox
  authorisation = MESH.generate_authorisation

  headers = {
    "Accept" => "application/vnd.mesh.v2+json",
    "Authorization" => "#{MESH::SCHEMA} #{authorisation}"
  }

  conn =
    Faraday.new("#{base_url}/messageexchange/#{mailbox}/inbox") do |faraday|
      faraday.ssl[:verify] = false if Rails.env.development?
      faraday.headers = headers
    end

  response = conn.get
  puts response.body
  warn response.status unless response.status == 200
end
