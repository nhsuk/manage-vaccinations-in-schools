example_campaign_file = "#{File.dirname(__FILE__)}/example-campaign.json"
schools_data_raw = [JSON.parse(File.read(example_campaign_file))["school"]]
schools_data =
  schools_data_raw.map do |school|
    {
      name: school["name"],
      urn: school["urn"],
      address: school["address"],
      locality: school["locality"],
      town: school["town"],
      county: school["county"],
      postcode: school["postcode"],
      minimum_age: school["minimum_age"],
      maximum_age: school["maximum_age"],
      url: school["url"],
      phase: school["phase"],
      type: school["type"],
      detailed_type: school["detailed_type"]
    }
  end

School.transaction do
  School.delete_all
  schools_data.each { |school_data| School.create!(**school_data) }
end
