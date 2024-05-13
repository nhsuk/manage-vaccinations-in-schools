require "faker"
require "csv"

class ExampleCampaignGenerator
  def self.patient_options
    %i[
      parents_that_have_registered_interest
      patients_with_no_session
      consent_forms_that_do_not_match
      consent_forms_that_partially_match
      patients_with_no_consent_response
      patients_with_consent_given_and_ready_to_vaccinate
      patients_with_consent_refused
      patients_with_conflicting_consent
      patients_that_still_need_triage
      patients_that_have_already_been_triaged
      patients_with_triage_started
    ]
  end

  def self.default_type
    :flu
  end

  def presettings
    @presettings ||= {
      default: {
        parents_that_have_registered_interest: 5,
        patients_with_no_session: 5,
        consent_forms_that_do_not_match: 2,
        consent_forms_that_partially_match: 2,
        patients_with_consent_given_and_ready_to_vaccinate: 2,
        patients_with_no_consent_response: 4,
        patients_with_consent_refused: 2,
        patients_with_conflicting_consent: 2,
        patients_that_still_need_triage: 2,
        patients_that_have_already_been_triaged: 2,
        patients_with_triage_started: 2
      },
      model_office: {
        type: :hpv,
        patients_with_consent_given_and_ready_to_vaccinate: 24,
        patients_with_no_consent_response: 16,
        patients_with_consent_refused: 15,
        patients_with_conflicting_consent: 3,
        patients_that_still_need_triage: 14,
        patients_that_have_already_been_triaged: 14,
        patients_with_triage_started: 4
      },
      empty_pilot: {
        type: :hpv,
        sessions: 0,
        schools_with_no_sessions: 1,
        parents_that_have_registered_interest: 5,
        patients_with_no_session: 5,
        patients_with_consent_given_and_ready_to_vaccinate: 0,
        patients_with_no_consent_response: 0,
        patients_with_consent_refused: 0,
        patients_with_conflicting_consent: 0,
        patients_that_still_need_triage: 0,
        patients_that_have_already_been_triaged: 0,
        patients_with_triage_started: 0
      }
    }.with_indifferent_access.freeze
  end

  attr_reader :random, :type, :options

  def initialize(seed: nil, presets: nil, **options)
    @random = seed ? Random.new(seed) : Random.new

    Faker::Config.locale = "en-GB"
    Faker::Config.random = @random

    @options = options
    @type = options.delete(:type)
    if @type && !@type.in?(%i[hpv flu])
      raise ArgumentError, "Invalid type #{@type}"
    end

    @username = options.delete(:username)
    @users_json = options.delete(:users_json)
    @sessions = options.delete(:sessions)&.to_i

    if presets
      raise "Preset #{presets} not found" unless presettings.key?(presets)
      @type ||= presettings[presets][:type] || self.class.default_type

      @username ||= presettings[presets][:username]
      raise "Username required" if @username.blank?

      @users_json ||= presettings[presets][:users_json]
      @sessions ||= presettings[presets].fetch(:sessions, 1).to_i
      @schools_with_no_sessions ||=
        presettings[presets].fetch(:schools_with_no_sessions, 0)
      @options = presettings[presets].merge(@options)
    else
      @type ||= self.class.default_type
    end
  end

  def generate
    sessions_data = @sessions.times.map { generate_session_data }
    school_data = @schools_with_no_sessions.times.map { generate_school_data }
    default_school =
      sessions_data.dig(0, :location) || school_data.dig(0, :name) ||
        generate_school_data[:name]
    vaccine_name = I18n.t("vaccines.#{type}")
    {
      id: random.seed.to_s,
      title: vaccine_name,
      type: vaccine_name,
      team: team_data,
      vaccines: vaccines_data,
      healthQuestions: health_answers_data,
      sessions: sessions_data,
      patientsWithNoSession: patients_with_no_session_data(default_school),
      schoolsWithNoSession: school_data
    }
  end

  def team_data
    @team_data ||= {
      name: team.name,
      email: team.email,
      privacyPolicyURL: team.privacy_policy_url,
      users:
        users.map { |user| { full_name: user.full_name, email: user.email } }
    }
  end

  def team
    id = @random.rand(1..1_000_000)

    @team ||=
      FactoryBot.build(
        :team,
        name: "SAIS team #{id}",
        email: "sais.#{id}@nhs.uk",
        privacy_policy_url: "https://www.nhs.uk/our-policies/"
      )
  end

  def users
    if @users_json.nil?
      full_name = @username
      email =
        "#{full_name.downcase.gsub(" ", ".").gsub(/[^a-z0-9.]/, "")}@example.com"
      @users_json = [{ full_name:, email: }].to_json
    end

    @users ||=
      JSON
        .parse(@users_json)
        .map do |user_hash|
          user_hash.with_indifferent_access => { full_name:, email: }
          FactoryBot.build(:user, teams: [team], full_name:, email:)
        end
  end

  def user
    users.first
  end

  def batches
    @batches ||=
      FactoryBot.create_list(
        :batch,
        3,
        random:,
        vaccine:,
        days_to_expiry_range: 90..180
      )
  end

  def batches_data
    @batches_data ||=
      batches.map { |batch| { name: batch.name, expiry: batch.expiry.iso8601 } }
  end

  def vaccine
    @vaccine ||= FactoryBot.build(:vaccine, @type)
  end

  def vaccines_data
    @vaccines_data ||= [
      { brand: vaccine.brand, method: vaccine.method, batches: batches_data }
    ]
  end

  def generate_session_data
    patients_consents_triage = []
    patients_consents_triage +=
      build_patients_with_consent_given_and_ready_to_vaccinate
    patients_consents_triage += build_patients_with_no_consent_response
    patients_consents_triage += build_patients_with_consent_refused
    patients_consents_triage += build_patients_with_conflicting_consent
    patients_consents_triage += build_patients_that_still_need_triage
    patients_consents_triage += build_patients_with_triage_started
    patients_consents_triage += build_patients_that_have_already_been_triaged

    patients_data = generate_patients_data(patients_consents_triage)
    patients_data = add_consents_to_patients_data(patients_data)

    school_data = generate_school_data

    consent_forms_data = generate_consent_forms_data(patients_data)

    {
      date: 28.days.from_now.iso8601,
      sendConsentAt: 14.days.from_now.iso8601,
      sendRemindersAt: 21.days.from_now.iso8601,
      closeConsentAt: 28.days.from_now.iso8601,
      location: school_data[:name],
      school: school_data,
      patients: patients_data,
      consent_forms: consent_forms_data
    }.with_indifferent_access
  end

  def generate_school_data
    JSON
      .parse(File.read(Rails.root.join("db/sample_data/schools_sample.json")))
      .sample(random:)
      .with_indifferent_access
  end

  def patients_with_no_session_data(location)
    count = options.fetch(:patients_with_no_session, 0)
    patients_locations =
      count.times.map do
        patient = build_patient
        { patient:, location: }
      end

    generate_patients_data(patients_locations)
  end

  def build_patient
    case @type
    when :hpv
      FactoryBot.build(:patient, :of_hpv_vaccination_age, random:)
    when :flu
      FactoryBot.build(:patient, random:)
    else
      raise ArgumentError, "Invalid type #{@type}"
    end
  end

  def build_consent(*options, **attrs)
    patient = attrs.fetch(:patient)
    unless (%i[from_mum from_dad from_granddad] & options).any?
      options << if patient.parent_relationship == "mother"
        :from_mum
      else
        :from_dad
      end
    end

    FactoryBot.build(
      :consent,
      *options,
      random:,
      campaign: nil,
      health_questions_list: health_answers_data.map { |hq| hq[:question] },
      **attrs
    )
  end

  def build_dual_consents(*options, **attrs)
    attrs[:reason_for_refusal] = reason_for_refusal if options.include?(
      :refused
    )

    mum_attrs = attrs.dup
    dad_attrs = attrs.dup

    # Randomise dad's reason in some cases where consent is refused
    dad_attrs[:reason_for_refusal] = reason_for_refusal if options.include?(
      :refused
    ) && random.rand(2).zero?

    [
      build_consent(:from_mum, *options, **mum_attrs),
      build_consent(:from_dad, *options, **dad_attrs)
    ].shuffle(random:)
  end

  def build_consents(number, *options, **attrs)
    case number
    when 1
      [build_consent(*options, **attrs)]
    when 2
      build_dual_consents(*options, **attrs)
    else
      raise ArgumentError, "Invalid number of consents #{number}"
    end
  end

  def build_conflicting_consents(*options, **attrs)
    giver_options, refuser_options =
      [options + [:from_dad], options + [:from_mum]].shuffle(random:)
    giver_options << :given
    refuser_options << :refused

    [
      build_consent(*giver_options, **attrs),
      build_consent(*refuser_options, **attrs.merge(reason_for_refusal:))
    ].shuffle(random:)
  end

  # consent given, no contraindications in health questions, ready to vaccinate
  def build_patients_with_consent_given_and_ready_to_vaccinate
    count =
      options.fetch(:patients_with_consent_given_and_ready_to_vaccinate, 0)
    count.times.map do
      patient = build_patient
      consents = build_consents(random_consents_number, :given, patient:)
      { patient:, consents: }
    end
  end

  # no consent response
  def build_patients_with_no_consent_response
    count = options.fetch(:patients_with_no_consent_response, 0)
    count.times.map do
      patient = build_patient
      { patient: }
    end
  end

  # refused
  def build_patients_with_consent_refused
    count = options.fetch(:patients_with_consent_refused, 0)
    count.times.map do
      patient = build_patient
      consents = build_consents(random_consents_number, :refused, patient:)
      { patient:, consents: }
    end
  end

  # conflicting consent
  def build_patients_with_conflicting_consent
    count = options.fetch(:patients_with_conflicting_consent, 0)
    count.times.map do
      patient = build_patient
      consents = build_conflicting_consents(patient:)
      { patient:, consents: }
    end
  end

  ################################################################
  # cases that still need triage
  #
  # The patient builders below rely on pre-generated health question responses
  # and notes for HPV, or randomly generated ones for flu.
  #
  # The pre-generated cases come in the form of CSV where each line represents
  # health question responses for a patient that has answered "Yes" to a health
  # question.
  def cases_that_still_need_triage_hpv(count)
    @cases_that_still_need_triage_hpv ||=
      CSV
        .parse(<<~CSV, headers: true)
        Does the child have any severe allergies that have led to an anaphylactic reaction?,Does the child have any existing medical conditions?,Does the child take any regular medication?,Is there anything else we should know?
        My child has a severe nut allergy and has had an anaphylactic reaction in the past. This is something that’s extremely important to me and my husband. We make sure to always have an EpiPen on hand.,,,
        ,My child was diagnosed with anaemia and has low iron levels.,,
        ,My child suffers from migraines and has severe headaches on a regular basis.,,
        ,Epilepsy,My child takes anti-seizure medication twice a day to manage their epilepsy.,
        ,My child has type 1 diabetes and requires daily insulin injections.,Insulin,
        ,My child has asthma,My child takes medication every day to manage their asthma.,
        ,Haemophilia,,My child has a bleeding disorder. In the past they’ve had injections in their thigh to reduce the risk of bleeding.
        ,,My child uses topical ointments to manage their eczema and prevent skin irritation.,
        ,,My child takes medication to manage their anxiety and prevent panic attacks.,
        ,,My child takes medication to manage their depression.,
        ,,My daughter takes the contraceptive pill to manage her acne.,
        ,,My daughter has just completed a long-term course of antibiotics for a urine infection.,
        ,,,My child has a history of fainting after receiving injections.
        ,,,My child recently had a bad reaction to a different vaccine. I just want to make sure we’re extra cautious with this.
      CSV
        .entries
        .map do |row|
          {
            health_answers:
              row.map do |question, notes|
                HealthAnswer.new(
                  question:,
                  response: notes.present? ? "Yes" : "No",
                  notes:
                )
              end
          }
        end
        .shuffle(random:)
        .cycle
        .first(count)
  end

  def cases_that_still_need_triage_flu(count)
    @cases_that_still_need_triage_flu ||=
      count.times.map do
        health_answers =
          health_answers_data.map do |hq|
            HealthAnswer.new(
              question: hq[:question],
              response: "no",
              notes: nil,
              hint: hq[:hint]
            )
          end
        health_answers
          .sample(random:)
          .tap do |hq|
            hq.response = "yes"
            hq.notes = "Generic note"
          end
        { health_answers: }
      end
  end

  def build_patients_that_still_need_triage
    count = options.fetch(:patients_that_still_need_triage, 0)
    return [] if count.zero?

    cases =
      case type
      when :flu
        cases_that_still_need_triage_flu(count)
      when :hpv
        cases_that_still_need_triage_hpv(count)
      else
        raise ArgumentError, "Invalid type #{type}"
      end

    cases.map do |example_case|
      patient = build_patient
      consents =
        build_consents(
          1,
          :given,
          health_answers: example_case[:health_answers],
          patient:
        )

      { patient:, consents: }
    end
  end

  ################################################################
  # cases where triage has been started
  def cases_with_triage_started_hpv(count)
    @cases_with_triage_started_hpv ||=
      CSV
        .parse(<<~CSV, headers: true)
      triage notes,Does the child have any severe allergies that have led to an anaphylactic reaction,Does the child have any existing medical conditions?,Does the child take any regular medication?,Is there anything else we should know?
      "Spoke to child’s mum. Child completed leukaemia treatment 6 months ago. Need to speak to the consultant who treated her for a view on whether it’s safe to vaccinate. Dr Goehring, King’s College, 0208 734 5432.",,My daughter has just finished treatment for leukaemia. I don’t know if it’s safe for her to have the vaccination.,,
      Tried to get hold of parent to establish how severe the phobia is. Try again before vaccination session.,,,,My son is needle phobic.
      Tried to get hold of parent to find out where the pain is. Try again before vaccination session.,,My child has chronic pain due to a previous injury and struggles with discomfort daily,,
      Tried to get hold of parent to find out what the surgery was for. Try again before vaccination session.,,,,Our child recently had surgery and is still recovering. We want to make sure it’s safe for them to get the vaccine.
    CSV
        .entries
        .map do |row|
          {
            triage_notes: row.delete("triage notes").second,
            health_answers:
              row.map do |question, notes|
                HealthAnswer.new(
                  question:,
                  response: notes.present? ? "Yes" : "No",
                  notes:
                )
              end
          }
        end
        .shuffle(random:)
        .cycle
        .first(count)
  end

  def cases_with_triage_started_flu(count)
    @cases_with_triage_started_flu ||=
      count.times.map do
        health_answers =
          health_answers_data.map do |hq|
            HealthAnswer.new(
              question: hq[:question],
              response: "no",
              notes: nil,
              hint: hq[:hint]
            )
          end
        health_answers
          .sample(random:)
          .tap do |hq|
            hq.response = "yes"
            hq.notes = "Generic note"
          end
        { triage_notes: "Generic triage notes", health_answers: }
      end
  end

  # patients with triage started
  def build_patients_with_triage_started
    count = options.fetch(:patients_with_triage_started, 0)
    return [] if count.zero?

    cases =
      case type
      when :flu
        cases_with_triage_started_flu(count)
      when :hpv
        cases_with_triage_started_hpv(count)
      else
        raise ArgumentError, "Invalid type #{type}"
      end

    cases.map do |patient_case|
      patient = build_patient
      consents =
        build_consents(
          [1, 2].sample(random:),
          :given,
          patient:,
          health_answers: patient_case[:health_answers]
        )
      triage = {
        notes: patient_case[:triage_notes],
        status: "needs_follow_up",
        user_email: user.email
      }
      { patient:, consents:, triage: }
    end
  end

  ################################################################
  # cases that have already been triaged
  def cases_that_have_already_been_triaged_hpv(count)
    cases_that_still_need_triage_hpv(count).map do |patient_case|
      patient_case.tap do |c|
        c[:triage_status] = %i[ready_to_vaccinate do_not_vaccinate].sample(
          random:
        )
        c[:triage_notes] = if c[:triage_status] == :ready_to_vaccinate
          "Checked with GP, OK to proceed"
        else
          "Checked with GP, not OK to proceed"
        end
        c[:user_email] = user.email
      end
    end
  end

  def cases_that_have_already_been_triaged_flu(count)
    cases_that_still_need_triage_flu(count).map do |patient_case|
      patient_case.tap do |c|
        c[:triage_status] = %i[ready_to_vaccinate do_not_vaccinate].sample(
          random:
        )
        c[:triage_notes] = if c[:triage_status] == :ready_to_vaccinate
          "Checked with GP, OK to proceed"
        else
          "Checked with GP, not OK to proceed"
        end
        c[:user_email] = user.email
      end
    end
  end

  def build_patients_that_have_already_been_triaged
    count = options.fetch(:patients_that_have_already_been_triaged, 0)
    return [] if count.zero?

    cases =
      case type
      when :flu
        cases_that_have_already_been_triaged_flu(count)
      when :hpv
        cases_that_have_already_been_triaged_hpv(count)
      else
        raise ArgumentError, "Invalid type #{type}"
      end

    cases.map do |patient_case|
      patient = build_patient
      consents =
        build_consents(
          1,
          :given,
          patient:,
          health_answers: patient_case[:health_answers]
        )
      %i[ready_to_vaccinate do_not_vaccinate].sample(random:)
      triage = {
        status: patient_case[:triage_status],
        notes: patient_case[:triage_notes],
        user_email: user.email
      }
      { patient:, consents:, triage: }
    end
  end

  def generate_patients_data(patients_consents_triage)
    patients_consents_triage.map do |patient_consent_triage|
      patient = patient_consent_triage[:patient]
      consents = patient_consent_triage[:consents]
      triage = patient_consent_triage[:triage]
      location = patient_consent_triage[:location]
      {
        firstName: patient.first_name,
        lastName: patient.last_name,
        dob: patient.date_of_birth.iso8601,
        nhsNumber: patient.nhs_number,
        consents:,
        parentEmail: patient.parent_email,
        parentName: patient.parent_name,
        parentPhone: patient.parent_phone,
        parentRelationship: patient.parent_relationship,
        parentRelationshipOther: patient.parent_relationship_other,
        triage:,
        location:
      }
    end
  end

  def add_consents_to_patients_data(patients_data)
    patients_data.each do |patient|
      next unless patient[:consents]
      consents = patient[:consents]
      patient[:consents] = consents.map do |consent|
        {
          response: consent.response,
          reasonForRefusal: consent.reason_for_refusal,
          parentName: consent.parent_name,
          parentRelationship: consent.parent_relationship,
          parentRelationshipOther: consent.parent_relationship_other,
          parentEmail: consent.parent_email,
          parentPhone: consent.parent_phone,
          healthQuestionResponses:
            consent.health_answers.map do |ha|
              {
                question: ha.question,
                response: ha.response,
                notes: ha.notes,
                hint: ha.hint
              }.compact
            end,
          route: consent.route
        }
      end
    end
  end

  def health_answers_data
    @health_answers_data ||=
      if @type == :flu
        [
          {
            id: 1,
            question: "Has your child been diagnosed with asthma?",
            next_question: 4,
            follow_up_question: 2
          },
          {
            id: 2,
            question: "Have they taken oral steroids in the last 2 weeks?",
            next_question: 3
          },
          {
            id: 3,
            question:
              "Have they been admitted to intensive care for their asthma?",
            next_question: 4
          },
          {
            id: 4,
            question:
              "Has your child had a flu vaccination in the last 5 months?",
            next_question: 5
          },
          {
            id: 5,
            question:
              "Does your child have a disease or treatment that severely affects their immune system?",
            hint:
              "For example, treatment for leukaemia or taking immunosuppressant medication",
            next_question: 6
          },
          {
            id: 6,
            question:
              "Is anyone in your household currently having treatment that severely affects their immune system?",
            hint: "For example, they need to be kept in isolation",
            next_question: 7
          },
          {
            id: 7,
            question:
              "Has your child ever been admitted to intensive care due to an allergic reaction to egg?",
            next_question: 8
          },
          {
            id: 8,
            question: "Does your child have any allergies to medication?",
            next_question: 9
          },
          {
            id: 9,
            question:
              "Has your child ever had a reaction to previous vaccinations?",
            next_question: 10
          },
          {
            id: 10,
            question: "Does you child take regular aspirin?",
            hint: "Also known as Salicylate therapy"
          }
        ].freeze
      else
        [
          {
            id: 1,
            question: "Does your child have any severe allergies?",
            next_question: 2
          },
          {
            id: 2,
            question:
              "Does your child have any medical conditions for which they receive treatment?",
            next_question: 3
          },
          {
            id: 3,
            question:
              "Has your child ever had a severe reaction to any medicines, including vaccines?"
          }
        ].freeze
      end
  end

  def random_consents_number
    # 70% chance of 1 consent, 30% chance of 2 consents
    [1, 1, 1, 1, 1, 1, 1, 2, 2, 2].sample(random:)
  end

  def reason_for_refusal
    %i[
      already_vaccinated
      will_be_vaccinated_elsewhere
      medical_reasons
      personal_choice
    ].sample(random:)
  end

  def generate_consent_forms_data(patients_data)
    consent_forms = []
    consent_forms +=
      build_consent_forms_that_do_not_match_patients(patients_data)
    consent_forms +=
      build_consent_forms_that_partially_match_patients(patients_data)

    consent_forms.map do |consent_form|
      consent_form.attributes.tap do |attrs|
        attrs.compact!
        attrs["health_answers"]&.map! do |ha_attrs|
          ha_attrs.attributes.except :id
        end
      end
    end
  end

  def build_consent_forms_that_do_not_match_patients(patients_data)
    return [] unless options.key?(:consent_forms_that_do_not_match)

    options[:consent_forms_that_do_not_match].times.map do
      cf =
        FactoryBot.build(
          :consent_form,
          random:,
          session: nil,
          recorded_at: random.rand(1..(14.days.to_i)).seconds.ago
        )

      patient_exists =
        patients_data.any? do |p|
          p[:firstName] == cf.first_name || p[:lastName] == cf.last_name
        end

      redo if patient_exists
      cf
    end
  end

  def build_consent_forms_that_partially_match_patients(patients_data)
    return [] unless options.key?(:consent_forms_that_partially_match)

    patients_data = patients_data.dup
    options[:consent_forms_that_partially_match].times.map do
      match_patient_on = %i[firstName lastName].sample(random:)
      patient = patients_data.delete(patients_data.sample(random:))

      FactoryBot.build(
        :consent_form,
        random:,
        session: nil,
        recorded_at: random.rand(1..(14.days.to_i)).seconds.ago,
        match_patient_on.to_s.underscore => patient[match_patient_on]
      )
    end
  end
end
