require "example_campaign_data"

desc "Load campaign example file into db"
task :load_campaign_example, [:example_file] => :environment do |_task, args|
  example_file =
    args.fetch(:example_file, "db/sample_data/example-campaign.json")

  example = ExampleCampaignData.new(data_file: Rails.root.join(example_file))

  Location.transaction do
    school = Location.find_or_create_by!(name: example.school_attributes[:name])
    school.update!(example.school_attributes)

    vaccine = Vaccine.find_or_create_by! name: example.vaccine_attributes[:name]

    campaign =
      Campaign.find_or_initialize_by name: example.campaign_attributes[:name]
    campaign.vaccine = vaccine
    campaign.save!

    session =
      Session.find_or_initialize_by(
        campaign:,
        name: example.session_attributes[:name]
      )
    session.update!(example.session_attributes)

    vaccine.health_questions =
      example.health_question_attributes.map do |attributes|
        HealthQuestion.find_or_initialize_by(attributes.merge(vaccine:))
      end

    example.children_attributes.each do |attributes|
      triage_attributes = attributes.delete(:triage)
      consent_attributes = attributes.delete(:consent)

      patient =
        Patient.find_or_initialize_by(nhs_number: attributes[:nhs_number])
      patient.update!(attributes)
      session.patients << patient unless session.patients.include?(patient)

      if triage_attributes.present?
        triage = Triage.find_or_initialize_by(campaign:, patient:)
        triage.update!(triage_attributes)
      end

      next if consent_attributes.blank?
      consent_response =
        ConsentResponse.find_or_initialize_by(campaign:, patient:)
      consent_response.update!(consent_attributes)
      unless patient.consent_responses.include?(consent_response)
        patient.consent_responses << consent_response
      end
    end
  end
end
