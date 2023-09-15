require "example_campaign_data"

desc "Load campaign example file into db"
task :load_campaign_example, [:example_file] => :environment do |_task, args|
  example_file =
    args.fetch(:example_file, "db/sample_data/example-campaign.json")

  example = ExampleCampaignData.new(data_file: Rails.root.join(example_file))

  Location.transaction do
    school = Location.find_or_create_by!(name: example.school_attributes[:name])
    school.update!(example.school_attributes)

    campaign =
      Campaign.find_or_initialize_by name: example.campaign_attributes[:name]
    campaign.save!

    example.vaccine_attributes.each do |attributes|
      batches = attributes.delete(:batches)
      vaccine = campaign.vaccines.find_or_create_by!(attributes)
      batches.each { |batch| vaccine.batches.find_or_create_by!(batch) }
    end

    session =
      Session.find_or_initialize_by(
        campaign:,
        name: example.session_attributes[:name]
      )
    session.update!(example.session_attributes)
    session.location = school if session.location.blank?
    session.save!

    vaccine = campaign.vaccines.first
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
      patient_session = PatientSession.find_or_create_by!(patient:, session:)

      if triage_attributes.present?
        triage = Triage.find_or_initialize_by(patient_session:)
        triage.update!(triage_attributes)
      end

      next if consent_attributes.blank?
      consent = Consent.find_or_initialize_by(campaign:, patient:)
      consent.update!(consent_attributes.merge(recorded_at: Time.zone.now))
      patient.consents << consent unless patient.consents.include?(consent)

      transition_states(patient.patient_sessions.first)

      create_user_for_environment(Rails.env)
    end
  end
end

def transition_states(patient_session)
  patient_session.do_consent if patient_session.may_do_consent?
  patient_session.do_triage if patient_session.may_do_triage?
  patient_session.do_vaccination if patient_session.may_do_vaccination?
  patient_session.save!
end

def create_user_for_environment(env)
  env_name = { "development" => "dev" }.fetch(env, env)

  User.find_or_create_by!(email: "nurse@#{env_name}") do |user|
    user.full_name = "Nurse Joy"
    user.password = "nurse@#{env_name}"
    user.password_confirmation = "nurse@#{env_name}"
  end
end
