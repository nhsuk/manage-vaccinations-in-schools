require "example_campaign_data"

module LoadExampleCampaign
  def self.load(example_file:, new_campaign: false, in_progress: false)
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

      team =
        Team.find_or_initialize_by(
          name: example.team_attributes[:name],
          email: example.team_attributes[:email],
          phone: "01234567890",
          privacy_policy_url: example.team_attributes[:privacy_policy_url]
        )
      team.campaigns << campaign unless campaign.in? team.campaigns
      create_users(team:, users: example.team_attributes[:users])

      campaign.save!

      create_vaccine_and_batches(example, campaign:)
      create_vaccine_health_questions(example, campaign:)

      example.sessions.each do |session_attributes|
        # HACK: Yes, this is a massive hack. If the "in_progress" cli flag is
        #       set, then we set all the sessions in this campaign to
        #       in-progress. Soz. At the moment we only use this option when
        #       loading single sessions (for tests or /reset), so embrace and
        #       iterate when needed.
        make_in_progress!(session_attributes:) if in_progress

        school =
          create_school(team:, school_attributes: session_attributes["school"])
        session = create_session(session_attributes, campaign:, school:)
        patient_attributes = example.children_attributes(session_attributes:)
        create_children(patient_attributes:, campaign:, session:)

        consent_forms =
          example.consent_form_attributes(session_attributes:) || []
        create_consent_forms(consent_forms:, session:)
      end

      schools_with_no_session =
        example.schools_with_no_session.map do |school_attributes|
          create_school(team:, school_attributes:)
        end

      create_children(
        patient_attributes: example.patients_with_no_session,
        campaign: nil,
        session: nil
      )

      location = team.locations.first || schools_with_no_session.first
      example.registrations.each do |registration_attributes|
        Registration.create!(
          registration_attributes.merge(
            location:,
            terms_and_conditions_agreed: true,
            data_processing_agreed: true,
            consent_response_confirmed: true,
            user_research_observation_agreed: true
          )
        )
      end
    end
  end

  def self.make_in_progress!(session_attributes:)
    session_attributes["date"] = Time.zone.today
    session_attributes["close_consent_at"] = Time.zone.today
    session_attributes["send_reminders_at"] = Time.zone.today - 7.days
    session_attributes["send_consent_at"] = Time.zone.today - 14.days
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

  def self.create_school(team:, school_attributes:)
    Location
      .find_or_create_by!(team:, name: school_attributes[:name])
      .tap { |school| school.update!(school_attributes) }
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

  def self.create_session(session_attributes, campaign:, school:)
    Session
      .find_or_initialize_by(campaign:, location: school)
      .tap do |session|
        session.update!(
          session_attributes.slice(
            "date",
            "send_consent_at",
            "send_reminders_at",
            "close_consent_at"
          )
        )
        session.update!(time_of_day: "morning")
        session.location = school if session.location.blank?
        session.save!
      end
  end

  def self.create_children(patient_attributes:, campaign:, session:)
    patient_attributes.each do |attributes|
      triage_attributes = attributes.delete(:triage)
      consents_attributes = attributes.delete(:consents)
      location_name = attributes.delete(:location)
      location =
        if location_name.blank?
          session&.location
        else
          Location.find_by(name: location_name)
        end

      patient =
        Patient.find_or_initialize_by(nhs_number: attributes[:nhs_number])
      patient.update!(attributes)
      patient.location = location
      patient.save!

      next if session.blank?
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

  def self.create_consent_forms(consent_forms:, session:)
    consent_forms.each do |attributes|
      health_answers =
        attributes
          .delete("health_answers")
          .map { |answer| HealthAnswer.new(answer) }
      session.consent_forms << ConsentForm.new(
        attributes.merge(health_answers:)
      )
    end
  end
end
