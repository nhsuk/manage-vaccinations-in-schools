require "example_campaign_data"

module LoadExampleCampaign
  def self.load(example_file:, new_campaign: false)
    example = ExampleCampaignData.new(data_file: Rails.root.join(example_file))

    ActiveRecord::Base.transaction do
      campaign =
        if new_campaign
          Campaign.new(example.campaign_attributes)
        else
          Campaign.find_or_initialize_by(
            name: example.campaign_attributes[:name]
          )
        end

      team = Team.find_or_initialize_by(name: example.team_attributes[:name])
      team.campaigns << campaign unless campaign.in? team.campaigns
      create_users(team:, users: example.team_attributes[:users])

      campaign.save!

      school = create_school(example)
      create_vaccine_and_batches(example, campaign:)
      session = create_session(example, campaign:, school:)

      create_vaccine_health_questions(example, campaign:)
      create_children(example, campaign:, session:)
    end
  end

  def self.transition_states(patient_session)
    patient_session.do_consent if patient_session.may_do_consent?
    patient_session.do_triage if patient_session.may_do_triage?
    patient_session.do_vaccination if patient_session.may_do_vaccination?
    patient_session.save!
  end

  def self.create_users(team:, users:)
    users.map do |attributes|
      email =
        attributes.fetch(:email) do
          username = attributes[:username]
          username ||= attributes[:full_name]&.downcase&.gsub(/\s+/, ".")
          env_name = { "development" => "dev" }.fetch(Rails.env, Rails.env)
          "#{username}@#{env_name}"
        end
      User
        .find_or_initialize_by(email:)
        .tap do |user|
          user.full_name = attributes[:full_name]
          user.password = email
          user.password_confirmation = email
          user.teams << team unless user.teams.include?(team)
          user.save!
        end
    end
  end

  def self.create_school(example)
    Location
      .find_or_create_by!(name: example.school_attributes[:name])
      .tap { |school| school.update!(example.school_attributes) }
  end

  def self.create_vaccine_and_batches(example, campaign:)
    example.vaccine_attributes.each do |attributes|
      batches = attributes.delete(:batches)
      vaccine = Vaccine.find_or_create_by!(attributes)
      batches.each { |batch| vaccine.batches.find_or_create_by!(batch) }
      campaign.vaccines << vaccine unless vaccine.in? campaign.vaccines
    end
  end

  def self.create_vaccine_health_questions(example, campaign:)
    vaccine = campaign.vaccines.first
    hq_id_mappings = {}
    example.health_question_attributes.each do |attributes|
      attrs = attributes.slice(:question, :hint).merge(vaccine:)
      hq = HealthQuestion.find_or_initialize_by(attrs)
      vaccine.health_questions << hq
      hq_id_mappings[attributes[:id]] = hq.id
    end

    set_next_and_follow_up_question_ids(example, hq_id_mappings)
  end

  def self.set_next_and_follow_up_question_ids(example, hq_id_mappings)
    example.health_question_attributes.each do |attributes|
      hq = HealthQuestion.find(hq_id_mappings[attributes[:id]])
      next_question_id = hq_id_mappings[attributes[:next_question]]
      follow_up_question_id = hq_id_mappings[attributes[:follow_up_question]]
      hq.update!(next_question_id:, follow_up_question_id:)
    end
  end

  def self.create_session(example, campaign:, school:)
    Session
      .find_or_initialize_by(campaign:, name: example.session_attributes[:name])
      .tap do |session|
        session.update!(example.session_attributes)
        session.location = school if session.location.blank?
        session.save!
      end
  end

  def self.create_children(example, campaign:, session:)
    example.children_attributes.each do |attributes|
      triage_attributes = attributes.delete(:triage)
      consents_attributes = attributes.delete(:consents)

      patient =
        Patient.find_or_initialize_by(nhs_number: attributes[:nhs_number])
      patient.update!(attributes)
      patient_session = PatientSession.find_or_create_by!(patient:, session:)

      if triage_attributes.present?
        patient_session.triage.destroy_all if patient_session.triage.present?
        user = User.find_by!(email: triage_attributes.delete(:user_email))
        triage = patient_session.triage.new
        triage.update!(triage_attributes.merge(user:))
      end

      next if consents_attributes.blank?
      consents_attributes.each do |consent_attributes|
        parent_email = consent_attributes[:parent_email]
        consent =
          Consent.find_or_initialize_by(campaign:, patient:, parent_email:)
        consent.update!(consent_attributes.merge(recorded_at: Time.zone.now))
        patient.consents << consent unless patient.consents.include?(consent)
      end

      transition_states(patient.patient_sessions.first)
    end
  end
end
