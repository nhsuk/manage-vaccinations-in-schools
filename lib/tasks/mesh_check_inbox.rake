# frozen_string_literal: true

desc "Check MESH inbox, listing any messages"
task "mesh:check_inbox" => :environment do
  response = MESH.connection.get("inbox")

  puts response.body
  warn response.status unless response.status == 200
end
