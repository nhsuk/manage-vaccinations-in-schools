# == Schema Information
#
# Table name: children
#
#  id         :bigint           not null, primary key
#  dob        :date
#  name       :string
#  nhs_number :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null

example_campaign_file = "#{File.dirname(__FILE__)}/example-campaign.json"
after "development:campaigns" do
  campaign_data_raw = JSON.parse(File.read(example_campaign_file))
  location = School.find_by(name: campaign_data_raw["location"])
  campaign =
    Campaign.find_by(
      location:,
      type: campaign_data_raw["type"],
      date: campaign_data_raw["date"]
    )
  children_data =
    campaign_data_raw["patients"].map do |patient|
      {
        seen: patient["seen"]["text"],
        first_name: patient["firstName"],
        last_name: patient["lastName"],
        dob: patient["dob"]
      }
    end

  Child.transaction do
    campaign.children.delete_all
    children_data.each { |child_data| campaign.children.create!(**child_data) }
  end
end
