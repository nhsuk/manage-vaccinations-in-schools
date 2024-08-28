# frozen_string_literal: true

namespace :pds do
  namespace :patient do
    desc "Retrieve patient using NHS number"
    task :find, [:nhs_number] => :environment do |_, args|
      nhs_number = args[:nhs_number]
      response = NHS::PDS::Patient.find(nhs_number)

      $stdout.puts response.status unless response.status == 200
      if $stdout.tty?
        puts response.env.url
        puts ""
        puts response.headers.map { "#{_1}: #{_2}" }
        puts ""
        puts JSON.pretty_generate(JSON.parse(response.body))
      else
        puts response.body
      end
    end
  end
end
