require "rake"

class DevController < ApplicationController
  skip_before_action :authenticate_user!

  def reset
    Rails.application.load_tasks

    ActiveRecord::Base.connection.transaction do
      data_tables =
        ActiveRecord::Base.connection.tables -
          %w[users schema_migrations ar_internal_metadata]
      data_tables.each do |table|
        ActiveRecord::Base.connection.execute(
          "TRUNCATE #{table} RESTART IDENTITY CASCADE"
        )
      end

      LoadExampleCampaign.load(
        example_file: "db/sample_data/example-test-campaign.json"
      )
      LoadExampleCampaign.load(
        example_file: "db/sample_data/example-flu-campaign.json",
        new_campaign: true
      )
    end

    redirect_to root_path
  end
end
