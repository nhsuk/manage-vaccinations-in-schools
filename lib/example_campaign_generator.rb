require "faker"

class ExampleCampaignGenerator
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
        patients_with_consent_given_and_ready_to_vaccinate: 24,
        patients_with_no_consent_response: 16,
        patients_with_consent_refused: 15,
        # Default behaviour is to generate patients for all the preset health
        # question responses we have for the following.
        patients_that_still_need_triage:
          health_question_responses_to_triage.length,
        patients_that_have_already_been_triaged:
          health_question_responses_to_triage.length,
        patients_with_triage_started:
          health_question_responses_triage_started.length
      }
    }.with_indifferent_access.freeze
  end

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

  attr_reader :random, :type, :options

  def initialize(seed: nil, type: :flu, presets: nil, **options)
    @random = seed ? Random.new(seed) : Random.new

    Faker::Config.locale = "en-GB"
    Faker::Config.random = @random

    @type = type
    @options = options
    if presets
      raise "Preset #{presets} not found" unless presettings.key?(presets)
      @options = presettings[presets].merge(@options)
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

    {
      id: random.seed.to_s,
      title: "#{type.upcase} campaign at #{school_data[:name]}",
      location: school_data[:name],
      date: "2023-07-28T12:30",
      type: type.upcase,
      team: team_data,
      vaccines: vaccines_data,
      school: school_data,
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
        nurse_name = Faker::Name.first_name
        FactoryBot.build(
          :user,
          teams: [team],
          full_name: "Nurse #{nurse_name}",
          email: "nurse.#{nurse_name.downcase}@sais"
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

  # cases to triage
  #
  # Each line represents health question responses for a patient that has
  # answered "Yes" to a health question.
  def health_question_responses_to_triage
    @health_question_responses_to_triage ||=
      CSV.parse(<<~CSV, headers: true).entries
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
  end

  # patients that still need triage
  def build_patients_that_still_need_triage
    count = options.fetch(:patients_that_still_need_triage, 0)
    health_question_responses_to_triage
      .shuffle(random:)
      .cycle
      .first(count)
      .map do |row|
        health_question_responses =
          row.map do |question, answer|
            {
              question:,
              response: answer.present? ? "Yes" : "No",
              notes: answer.presence
            }
          end

        patient = build_patient
        consent =
          build_consent(
            :given,
            health_questions: health_question_responses,
            patient:
          )
        [patient, consent]
      end
  end

  # cases where triage has been started
  def health_question_responses_triage_started
    @health_question_responses_triage_started ||=
      CSV.parse(<<~CSV, headers: true).entries
      triage notes,Does the child have any severe allergies that have led to an anaphylactic reaction,Does the child have any existing medical conditions?,Does the child take any regular medication?,Is there anything else we should know?
      "Spoke to child’s mum. Child completed leukaemia treatment 6 months ago. Need to speak to the consultant who treated her for a view on whether it’s safe to vaccinate. Dr Goehring, King’s College, 0208 734 5432.",,My daughter has just finished treatment for leukaemia. I don’t know if it’s safe for her to have the vaccination.,,
      Tried to get hold of parent to establish how severe the phobia is. Try again before vaccination session.,,,,My son is needle phobic.
      Tried to get hold of parent to find out where the pain is. Try again before vaccination session.,,My child has chronic pain due to a previous injury and struggles with discomfort daily,,
      Tried to get hold of parent to find out what the surgery was for. Try again before vaccination session.,,,,Our child recently had surgery and is still recovering. We want to make sure it’s safe for them to get the vaccine.
    CSV
  end

  # patients with triage started
  def build_patients_with_triage_started
    count = options.fetch(:patients_with_triage_started, 0)
    health_question_responses_triage_started
      .shuffle(random:)
      .cycle
      .first(count)
      .map do |row|
        health_question_responses =
          row.map do |question, answer|
            if question == "triage notes"
              nil
            else
              {
                question:,
                response: answer.present? ? "Yes" : "No",
                notes: answer.presence
              }
            end
          end

        patient = build_patient
        consent =
          build_consent(
            :given,
            patient:,
            health_questions: health_question_responses.compact
          )
        triage = { notes: row["triage notes"], status: "needs_follow_up" }
        [patient, consent, triage]
      end
  end

  # cases that have already been triaged
  def build_patients_that_have_already_been_triaged
    count = options.fetch(:patients_that_have_already_been_triaged, 0)
    health_question_responses_to_triage
      .shuffle(random:)
      .cycle
      .first(count)
      .map do |row|
        health_question_responses =
          row.map do |question, answer|
            {
              question:,
              response: answer.present? ? "Yes" : "No",
              notes: answer.presence
            }
          end

        patient = build_patient
        consent =
          build_consent(
            :given,
            patient:,
            health_questions: health_question_responses
          )
        status = %i[ready_to_vaccinate do_not_vaccinate].sample(random:)
        triage = {
          status:,
          notes:
            (
              if status == :ready_to_vaccinate
                "Checked with GP, OK to proceed"
              else
                "Checked with GP, not OK to proceed"
              end
            )
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
end
