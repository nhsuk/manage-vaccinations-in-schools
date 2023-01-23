class ExampleCampaignData
  def initialize(data_file:)
    @data_file = data_file
  end

  def raw_data
    @raw_data ||= JSON.parse(File.read(@data_file))
  end

  def campaign_attributes
    { date: raw_data["date"], type: raw_data["type"] }
  end

  def campaign_location_name
    raw_data["location"]
  end

  def school_attributes
    school_data = raw_data["school"]
    {
      name: school_data["name"],
      urn: school_data["urn"],
      address: school_data["address"],
      locality: school_data["locality"],
      town: school_data["town"],
      county: school_data["county"],
      postcode: school_data["postcode"],
      minimum_age: school_data["minimum_age"],
      maximum_age: school_data["maximum_age"],
      url: school_data["url"],
      phase: school_data["phase"],
      type: school_data["type"],
      detailed_type: school_data["detailed_type"]
    }
  end

  def children_attributes
    raw_data["patients"].map do |patient|
      {
        seen: patient["seen"]["text"],
        first_name: patient["firstName"],
        last_name: patient["lastName"],
        dob: patient["dob"],
        sex: patient["sex"],
        consent: patient["consent"],
        gp: patient["gp"],
        nhs_number: patient["nhsNumber"],
        screening: patient["screening"]
      }
    end
  end
end
