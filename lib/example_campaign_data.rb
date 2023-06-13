class ExampleCampaignData
  def initialize(data_file:)
    @data_file = data_file
  end

  def raw_data
    @raw_data ||= JSON.parse(File.read(@data_file))
  end

  def campaign_attributes
    { name: raw_data["type"] }
  end

  def session_attributes
    { date: raw_data["date"], name: raw_data["title"] }
  end

  def campaign_location_name
    raw_data["location"]
  end

  def school_attributes
    school_data = raw_data["school"]
    {
      name: school_data["name"],
      address: school_data["address"],
      locality: school_data["locality"],
      town: school_data["town"],
      county: school_data["county"],
      postcode: school_data["postcode"],
      url: school_data["url"]
    }
  end

  def children_attributes
    raw_data["patients"].map do |patient|
      attributes = {
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

      if patient["triage"].present?
        attributes[:triage] = {
          status: patient["triage"]["status"],
          notes: patient["triage"]["notes"]
        }
      end

      attributes
    end
  end
end
