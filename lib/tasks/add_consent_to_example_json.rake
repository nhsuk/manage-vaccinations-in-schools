require "example_campaign_data"
require "faker"

# This rake task is used to add consent responses to the example json file. It
# is run once to generate the example-campaign-new.json file. It is not
# intended to be run again. It's left here for reference and in case we need to
# do something similar in the future.
#
# Because it only needs to be run once, it outputs the new json to stdout and
# replacing the example-campaign.json file is left as an exercise for the reader.
#
#     $ rails add_consent_to_example_json > db/sample_data/example-campaign-new.json
#     $ mv db/sample_data/example-campaign-new.json db/sample_data/example-campaign.json

# rubocop:disable Rails/SaveBang
desc "Add consent responses to example json"
task :add_consent_to_example_json, [:name] => :environment do |_task, args|
  Faker::Config.locale = "en-GB"

  example =
    JSON.parse(
      File.read(Rails.root.join("db/sample_data/example-campaign.json"))
    )

  if args[:name].present?
    # If given a name, just generate a consent response for that patient and
    # output it
    example_patient =
      example["patients"].find { |patient| patient["fullName"] == args[:name] }

    consent = generate_consent(example_patient, allow_none: false)
    consent.update generate_consent_for_example_patient(example_patient)

    puts JSON.pretty_generate(consent)
  else
    # Otherwise, generate consent responses for all patients
    example["patients"].each_with_index do |patient, _index|
      # Minor fixup as we go
      patient["dob"] = Date.parse(patient["dob"]).to_s

      consent = generate_consent(patient)

      if consent.nil?
        patient.delete("consent")
      else
        consent.update generate_consent_for_example_patient(patient)

        patient["consent"] = consent
      end
    end

    puts JSON.pretty_generate(example)
  end
end

def generate_consent_for_example_patient(patient)
  {}.merge generate_common_name,
          generate_dob(patient),
          generate_address(patient),
          generate_parents(patient),
          generate_route(patient)
end

def generate_consent(_patient, allow_none: true)
  # Adjust the randomness if don't allow "no consent response" here
  randomness = allow_none ? Random.rand(0.0..1.0) : Random.rand(0.3..1.0)

  case randomness
  when 0.0..0.3
    consent = nil
  when 0.3..0.5 # consent refused
    consent = {
      consent: :refused,
      reasonForRefusal: Consent.reason_for_refusals.keys.sample
    }

    if consent[:reasonForRefusal] == "other"
      consent[:reasonForRefusalOtherReason] = Faker::Movies::VForVendetta.quote
    end
  else # consent given
    consent = { consent: :given }
  end

  consent
end

def generate_common_name
  response = {}

  if Random.rand(0.0..1.0) < 0.5
    common_name =
      begin
        Faker::Name.name
      rescue StandardError
        nil
      end
    response[:commonName] = common_name if common_name.present?
  end

  response
end

def generate_dob(patient)
  dob =
    if Random.rand(0.0..1.0) < 0.8
      Date.parse(patient["dob"])
    else
      Faker::Date.between(
        from: 1.year.before(Date.parse(patient["dob"])),
        to: 1.year.after(Date.parse(patient["dob"]))
      )
    end

  { dob: }
end

def generate_address(_patient)
  address = {
    addressLine1: Faker::Address.street_address,
    addressTown: Faker::Address.city,
    addressPostcode: Faker::Address.postcode
  }
  address[:addressLine2] = Faker::Address.secondary_address if Random.rand(
    0.0..1.0
  ) > 0.8

  address
end

def generate_parents(patient)
  example_parent = patient["parentOrGuardian"]
  parent = {}

  parent[:parentName] = example_parent["Name"]
  parent[:parentRelationship] = case example_parent["relationship"]
  when "Parent"
    example_parent["sex"] == "Male" ? "father" : "mother"
  when "Guardian"
    "guardian"
  else
    "other"
  end

  if parent[:parentRelationship] == "other"
    parent[:parentRelationshipOther] = case example_parent["sex"]
    when "Male"
      %w[grandfather uncle].sample
    else
      %w[grandmother aunt].sample
    end
  end
  parent[:parentName] = example_parent["fullName"]
  parent[:parentEmail] = example_parent["email"]

  parent
end

def generate_route(_patient)
  route = Random.rand(0.0..1.0) < 0.5 ? "website" : Consent.routes.keys.sample
  { route: }
end

# rubocop:enable Rails/SaveBang
