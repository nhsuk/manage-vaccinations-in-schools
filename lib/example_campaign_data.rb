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

      if patient["consent"].present?
        consent_example = patient["consent"]
        consent = {}

        consent[:consent] = consent_example["consent"]
        consent[:reason_for_refusal] = consent_example["reasonForRefusal"]
        consent[:reason_for_refusal_other] = consent_example[
          "reasonForRefusalOtherReason"
        ]

        consent[:childs_name] = consent_example["childsName"]
        consent[:childs_dob] = consent_example["childsDob"]
        consent[:childs_common_name] = consent_example["childsCommonName"]

        consent[:address_line_1] = consent_example["addressLine1"]
        consent[:address_line_2] = consent_example["addressLine2"]
        consent[:address_postcode] = consent_example["addressPostcode"]
        consent[:address_town] = consent_example["addressTown"]

        consent[:parent_name] = consent_example["parentName"]
        consent[:parent_relationship] = consent_example["parentRelationship"]
        consent[:parent_relationship_other] = consent_example[
          "parentRelationshipOther"
        ]
        consent[:parent_email] = consent_example["parentEmail"]
        consent[:parent_phone] = consent_example["parentPhone"]
        consent[:parent_contact_method] = consent_example["parentContactMethod"]
        consent[:parent_contact_method_other] = consent_example[
          "parentContactMethodOther"
        ]

        consent[:gp_response] = consent_example["gpResponse"]
        consent[:gp_name] = consent_example["gpName"]

        consent[:route] = consent_example["route"]

        attributes[:consent] = consent
      end

      attributes
    end
  end
end
