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

    desc "Find patient using patient info"
    task find_by: :environment do |_, _args|
      query = {
        "_fuzzy-match" => ENV["_fuzzy_match"],
        "_exact-match" => ENV["_exact_match"],
        "_history" => ENV["_history"],
        "_max-results" => ENV["_max_results"],
        "given" => ENV["given"],
        "family" => ENV["family"],
        "gender" => ENV["gender"],
        "birthdate" => ENV["birthdate"],
        "death-date" => ENV["death_date"],
        "email" => ENV["email"],
        "phone" => ENV["phone"],
        "address-postcode" => ENV["address_postcode"],
        "general-practitioner" => ENV["general_practitioner"]
      }.compact
      response = NHS::PDS::Patient.find_by(**query)

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
