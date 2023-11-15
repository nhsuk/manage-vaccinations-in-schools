require "faker"

class ExampleCampaignGenerator
  def self.patient_options
    %i[
      patients_with_no_consent_response
      patients_with_consent_given_and_ready_to_vaccinate
      patients_with_consent_refused
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
        patients_with_consent_given_and_ready_to_vaccinate: 2,
        patients_with_no_consent_response: 2,
        patients_with_consent_refused: 2,
        patients_that_still_need_triage: 2,
        patients_that_have_already_been_triaged: 2,
        patients_with_triage_started: 2
      },
      model_office: {
        type: :hpv,
        patients_with_consent_given_and_ready_to_vaccinate: 24,
        patients_with_no_consent_response: 16,
        patients_with_consent_refused: 15,
        patients_that_still_need_triage: 14,
        patients_that_have_already_been_triaged: 14,
        patients_with_triage_started: 4
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

    if presets
      raise "Preset #{presets} not found" unless presettings.key?(presets)
      @type ||= presettings[presets][:type] || self.class.default_type
      @username ||= presettings[presets][:username]
      @options = presettings[presets].merge(@options)
    else
      @type ||= self.class.default_type
    end
  end

  def generate
    patients_consent_triage = []
    patients_consent_triage +=
      build_patients_with_consent_given_and_ready_to_vaccinate
    patients_consent_triage += build_patients_with_no_consent_response
    patients_consent_triage += build_patients_with_consent_refused
    patients_consent_triage += build_patients_that_still_need_triage
    patients_consent_triage += build_patients_with_triage_started
    patients_consent_triage += build_patients_that_have_already_been_triaged

    patients_data = generate_patients_data(patients_consent_triage)
    patients_data = add_consent_to_patients_data(patients_data)
    patients_data = match_mum_and_dad_info_to_consent(patients_data)

    vaccine_name = I18n.t("vaccines.#{type}")
    {
      id: random.seed.to_s,
      title: "#{vaccine_name} campaign at #{school_data[:name]}",
      location: school_data[:name],
      date: "2023-07-28T12:30",
      type: vaccine_name,
      team: team_data,
      vaccines: vaccines_data,
      school: school_data,
      healthQuestions: health_questions_data,
      patients: patients_data
    }
  end

  def team_data
    @team_data ||= {
      name: team.name,
      users: [{ full_name: user.full_name, email: user.email }]
    }
  end

  def team
    @team = FactoryBot.build(:team, name: "#{school_data[:county]} SAIS team")
  end

  def user
    @user ||=
      begin
        username = @username || "Nurse #{Faker::Name.first_name}"
        emailname = username.downcase.gsub(" ", ".").gsub(/[^a-z0-9.]/, "")
        FactoryBot.build(
          :user,
          teams: [team],
          full_name: username,
          email: "#{emailname}@example.com"
        )
      end
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

  def build_patient
    case @type
    when :hpv
      FactoryBot.build(:patient, :of_hpv_vaccination_age, random:)
    when :flu
      FactoryBot.build(:patient, random:)
    end
  end

  def build_consent(*options, **attrs)
    options << @type
    carer_options = %i[from_mum from_dad]
    options << carer_options.sample(random:) unless carer_options.in? options

    FactoryBot.build(:consent, *options, random:, campaign: nil, **attrs)
  end

  # consent given, no contraindications in health questions, ready to vaccinate
  def build_patients_with_consent_given_and_ready_to_vaccinate
    count =
      options.fetch(:patients_with_consent_given_and_ready_to_vaccinate, 0)
    count.times.map do
      patient = build_patient
      consent = build_consent(:given, patient:)
      [patient, consent]
    end
  end

  # no consent response
  def build_patients_with_no_consent_response
    count = options.fetch(:patients_with_no_consent_response, 0)
    count.times.map do
      patient = build_patient
      [patient, nil]
    end
  end

  # refused
  def build_patients_with_consent_refused
    count = options.fetch(:patients_with_consent_refused, 0)
    count.times.map do
      patient = build_patient
      consent =
        build_consent(
          :refused,
          reason_for_refusal: %i[personal_choice already_vaccinated].sample(
            random:
          ),
          patient:
        )
      [patient, consent]
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
            health_questions:
              row.map do |question, notes|
                { question:, response: notes.present? ? "Yes" : "No", notes: }
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
        health_questions =
          health_questions_data.map do |hq|
            {
              question: hq[:question],
              response: "no",
              notes: nil,
              hint: hq[:hint]
            }
          end
        health_questions
          .sample(random:)
          .tap do |hq|
            hq[:response] = "yes"
            hq[:notes] = "Generic note"
          end
        { health_questions: }
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
      end

    cases.map do |example_case|
      patient = build_patient
      consent =
        build_consent(
          :given,
          health_questions: example_case[:health_questions],
          patient:
        )
      [patient, consent]
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
            health_questions:
              row.map do |question, notes|
                { question:, response: notes.present? ? "Yes" : "No", notes: }
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
        health_questions =
          health_questions_data.map do |hq|
            {
              question: hq[:question],
              response: "no",
              notes: nil,
              hint: hq[:hint]
            }
          end
        health_questions
          .sample(random:)
          .tap do |hq|
            hq[:response] = "yes"
            hq[:notes] = "Generic note"
          end
        { triage_notes: "Generic triage notes", health_questions: }
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
      end

    cases.map do |patient_case|
      patient = build_patient
      consent =
        build_consent(
          :given,
          patient:,
          health_questions: patient_case[:health_questions]
        )
      triage = { notes: patient_case[:triage_notes], status: "needs_follow_up" }
      [patient, consent, triage]
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
      end

    cases.map do |patient_case|
      patient = build_patient
      consent =
        build_consent(
          :given,
          patient:,
          health_questions: patient_case[:health_questions]
        )
      %i[ready_to_vaccinate do_not_vaccinate].sample(random:)
      triage = {
        status: patient_case[:triage_status],
        notes: patient_case[:triage_notes]
      }
      [patient, consent, triage]
    end
  end

  def generate_patients_data(patients_consent_triage)
    patients_consent_triage.map do |patient, consent, triage|
      {
        firstName: patient.first_name,
        lastName: patient.last_name,
        dob: patient.dob.iso8601,
        nhsNumber: patient.nhs_number,
        consent:,
        parentEmail: patient.parent_email,
        parentName: patient.parent_name,
        parentPhone: patient.parent_phone,
        parentRelationship: patient.parent_relationship,
        parentRelationshipOther: patient.parent_relationship_other,
        parentInfoSource: patient.parent_info_source,
        triage:
      }
    end
  end

  def add_consent_to_patients_data(patients_data)
    patients_data.each do |patient|
      next unless patient[:consent]
      consent = patient[:consent]
      patient[:consent] = {
        response: consent.response,
        reasonForRefusal: consent.reason_for_refusal,
        parentName: consent.parent_name,
        parentRelationship: consent.parent_relationship,
        parentEmail: consent.parent_email,
        parentPhone: consent.parent_phone,
        healthQuestionResponses: consent.health_questions,
        route: consent.route
      }
    end
  end

  # match mum and dad info for patients with parental consent
  def match_mum_and_dad_info_to_consent(patients_data)
    patients_data.each do |patient|
      unless patient[:consent].present? &&
               patient[:consent][:parentRelationship].in?(%w[mother father]) &&
               patient[:consent][:parentRelationship] ==
                 patient[:parentRelationship]
        next
      end

      patient[:parentName] = patient[:consent][:parentName]
      patient[:parentRelationship] = patient[:consent][:parentRelationship]
      patient[:parentEmail] = patient[:consent][:parentEmail]
      patient[:parentPhone] = patient[:consent][:parentPhone]
    end
  end

  def school_data
    @school_data ||=
      JSON
        .parse(File.read(Rails.root.join("db/sample_data/schools_sample.json")))
        .sample(random:)
        .with_indifferent_access
  end

  def health_questions_data
    @health_questions_data ||=
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
        [].freeze
      end
  end
end
