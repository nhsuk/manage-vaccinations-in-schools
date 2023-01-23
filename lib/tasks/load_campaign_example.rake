require "example_campaign_data"

desc "Load campaign example file into db"
task load_campaign_example: :environment do
  example =
    ExampleCampaignData.new(
      data_file: Rails.root.join("db/sample_data/example-campaign.json")
    )

  school = School.find_or_create_by!(urn: example.school_attributes[:urn])
  school.update!(example.school_attributes)

  campaign =
    Campaign.find_or_create_by!(
      type: example.campaign_attributes[:type],
      date: example.campaign_attributes[:date],
      location: school
    )
  campaign.save!

  example.children_attributes.each do |child_attributes|
    child =
      campaign.children.find_or_create_by!(
        nhs_number: child_attributes[:nhs_number]
      )
    child.update!(child_attributes)
  end
end
