#frozen_string_literal: true

module MavisCLI
  module PDS
    class Get < Dry::CLI::Command
      desc "Get a patient by NHS number"

      argument :nhs_number, required: true, desc: "NHS number"

      def call(nhs_number:)
        MavisCLI.load_rails

        response = NHS::PDS.get_patient(nhs_number)

        puts response.status unless response.status == 200
        puts response.env.url
        puts ""
        puts(response.headers.map { "#{_1}: #{_2}" })
        puts ""
        puts JSON.pretty_generate(response.body)
      end
    end
  end

  register "pds" do |prefix|
    prefix.register "get", PDS::Get
  end
end
