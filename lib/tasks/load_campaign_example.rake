require "example_campaign_data"

desc "Load campaign example file into db"
task load_campaign_example: :environment do
  example =
    ExampleCampaignData.new(
      data_file: Rails.root.join("db/sample_data/example-campaign.json")
    )

  school = Location.find_or_create_by!(name: example.school_attributes[:name])
  school.update!(example.school_attributes)

  campaign =
    Campaign.find_or_create_by!(name: example.campaign_attributes[:name])
  campaign.save!

  session =
    Session.find_or_create_by!(
      campaign:,
      name: example.session_attributes[:name]
    )
  session.update!(example.session_attributes)

  example.children_attributes.each do |child_attributes|
    child =
      session.patients.find_or_create_by!(
        nhs_number: child_attributes[:nhs_number]
      )
    child.update!(child_attributes)
  end
end
