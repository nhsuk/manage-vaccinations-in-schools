require "rake"

Rails.application.load_tasks

class DevController < ApplicationController
  def reset
    Rake::Task["db:schema:load"].invoke
    Rake::Task["load_campaign_example"].invoke(
      "db/sample_data/example-test-campaign.json"
    )
    redirect_to root_path
  end
end
