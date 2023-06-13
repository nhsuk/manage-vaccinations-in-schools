require "example_campaign_data"

desc "Load campaign example file into db"
task load_campaign_example: :environment do
  example =
    ExampleCampaignData.new(
      data_file: Rails.root.join("db/sample_data/example-campaign.json")
    )

  Location.transaction do
    school = Location.find_or_create_by!(name: example.school_attributes[:name])
    school.update!(example.school_attributes)

    campaign =
      Campaign.find_or_create_by!(name: example.campaign_attributes[:name])
    campaign.save!

    session =
      Session.find_or_initialize_by(
        campaign:,
        name: example.session_attributes[:name]
      )
    session.update!(example.session_attributes)

    example.children_attributes.each do |attributes|
      triage_attributes = attributes.delete(:triage)

      child = Patient.find_or_initialize_by(nhs_number: attributes[:nhs_number])
      child.update!(attributes)
      session.patients << child

      next if triage_attributes.blank?
      triage = Triage.new(triage_attributes)
      triage.campaign = campaign
      child.triage << triage
    end
  end
end
