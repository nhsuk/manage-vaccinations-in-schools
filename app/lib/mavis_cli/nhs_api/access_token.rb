#frozen_string_literal: true

module MavisCLI
  module NHSAPI
    class AccessToken < Dry::CLI::Command
      desc "Fetch and display an access token for the NHS API"

      def call
        MavisCLI.load_rails

        puts NHS::API.access_token
      end
    end
  end

  register "nhs-api" do |prefix|
    prefix.register "access-token", NHSAPI::AccessToken
  end
end
