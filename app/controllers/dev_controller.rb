require "rake"

Rails.application.load_tasks

class DevController < ApplicationController
  def reset
    Rake::Task["db:schema:load"].execute
    Rake::Task["load_campaign_example"].execute(
      example_file: "db/sample_data/example-test-campaign.json"
    )
    redirect_to root_path
  end
end
