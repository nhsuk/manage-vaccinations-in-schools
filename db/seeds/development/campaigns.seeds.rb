after "development:schools" do
  example_campaign_file = "#{File.dirname(__FILE__)}/example-campaign.json"
  campaign_data_raw = JSON.parse(File.read(example_campaign_file))

  location = School.find_by(name: campaign_data_raw["location"])
  campaign_data = {
    date: campaign_data_raw["date"],
    type: campaign_data_raw["type"],
    location:
  }

  Campaign.transaction do
    Campaign.delete_all
    Campaign.find_or_create_by!(**campaign_data)
  end
end
