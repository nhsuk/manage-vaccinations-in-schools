# frozen_string_literal: true

namespace :nhs do
  desc "Get an access token to test with"
  task access_token: :environment do |_, _args|
    puts NHS::API.access_token
  end
end
