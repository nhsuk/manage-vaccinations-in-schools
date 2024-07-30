# frozen_string_literal: true

desc "Get message from MESH"
task "mesh:get_message", [:message] => :environment do |_, args|
  message = args[:message]

  response = MESH.connection.get("inbox/#{message}")

  puts response.body
  warn response.status unless response.status == 200
end
