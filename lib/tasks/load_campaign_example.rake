require "example_campaign_data"

def data_already_exists_abort_message(dataset_name:)
  <<~EOMSG
Please manually delete/truncate the existing #{dataset_name} data to continue.
We don't do this automatically to avoid unfortunate accidents. If you want to
continue, run:

  $ rails db
  psql (13.5)
  Type "help" for help.

  record_childrens_vaccinations_development=# TRUNCATE #{dataset_name};

    EOMSG
end

def assert_dataset_is_empty(model:)
  if model.any?
    puts data_already_exists_abort_message(dataset_name: model.table_name)
    raise "#{model} data already exists, aborting."
  end
end

desc "Load campaign example file into db"
task load_campaign_example: :environment do
  example =
    ExampleCampaignData.new(
      data_file: Rails.root.join("db/sample_data/example-campaign.json")
    )
  assert_dataset_is_empty(model: Campaign)
  assert_dataset_is_empty(model: School)
  assert_dataset_is_empty(model: Child)

  School.create!(**example.school_attributes)

  campaign = Campaign.create!(**example.campaign_attributes)
  campaign.location = School.find_by(name: example.campaign_location_name)
  campaign.save!

  example.children_attributes.each do |child_attributes|
    campaign.children.create!(**child_attributes)
  end
end
