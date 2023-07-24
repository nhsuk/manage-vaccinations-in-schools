require "faker"

# rubocop:disable Lint/ConstantDefinitionInBlock
desc "Generate test scenarios to support the model office"
task :generate_model_office_data, [] => :environment do |_task, _args|
  Faker::Config.locale = "en-GB"
  target_filename = "db/sample_data/model-office.json"

  hpv_vaccine = {
    brand: "Gardasil 9",
    method: "Injection",
    batches: [
      { name: "IE5343", expiry: "2024-02-01" },
      { name: "IE6279", expiry: "2024-01-18" },
      { name: "IE3943", expiry: "2024-01-25" }
    ]
  }

  school_details = {
    urn: "136295",
    name: "Holyrood Academy",
    address: "Zembard Lane",
    locality: "",
    address3: "",
    town: "Chard",
    county: "Somerset",
    postcode: "TA20 1JL",
    minimum_age: "11",
    maximum_age: "18",
    url: "https://holyrood.uat.ac/",
    phase: "Secondary",
    type: "Academy converter",
    detailed_type: "Academy converter"
  }

  patients_consent_triage = []

  # about 50% yes from parent or guardian, no yes answers or notes, in state ready to vaccinate
  100.times do
    patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
    consent =
      FactoryBot.build(
        :consent_response,
        :given,
        %i[from_mum from_dad].sample,
        :health_question_hpv_no_contraindications,
        patient:,
        campaign: nil
      )
    patients_consent_triage << [patient, consent]
  end

  # about 20% no consent response
  40.times do
    patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
    patients_consent_triage << [patient, nil]
  end

  # about 10% refused
  20.times do
    patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
    consent =
      FactoryBot.build(
        :consent_refused,
        %i[from_mum from_dad].sample,
        reason_for_refusal: %i[personal_choice already_vaccinated].sample,
        patient:,
        campaign: nil
      )
    patients_consent_triage << [patient, consent]
  end

  # cases to triage
  TO_TRIAGE = <<~CSV.freeze
  Does the child have any severe allergies that have led to an anaphylactic reaction?,Does the child have any existing medical conditions?,Does the child take any regular medication?,Is there anything else we should know?
  My child has a severe nut allergy and has had an anaphylactic reaction in the past. This is something that’s extremely important to me and my husband. We make sure to always have an EpiPen on hand.,,,
  "Yes, my child has a food allergy to dairy products.",,,
  ,My child was diagnosed with anaemia and has low iron levels.,,
  ,My child suffers from migraines and has severe headaches on a regular basis.,,
  ,My child has celiac disease.,,
  ,Epilepsy,My child takes anti-seizure medication twice a day to manage their epilepsy.,
  ,My child has type 1 diabetes and requires daily insulin injections.,Insulin,
  ,My child has asthma,My child takes medication every day to manage their asthma.,
  ,,My child takes medication to manage their ADHD.,
  ,,My child uses topical ointments to manage their eczema and prevent skin irritation.,
  ,,My child takes medication to manage their anxiety and prevent panic attacks.,
  ,,My child takes medication to manage their depression.,
  ,,My daughter takes the contraceptive pill to manage her acne.,
  ,,My daughter has just completed a long-term course of antibiotics for a urine infection.,
  ,,,My child has a history of fainting after receiving injections.
  ,,,My child recently had a bad reaction to a different vaccine. I just want to make sure we’re extra cautious with this.
  CSV

  CSV
    .parse(TO_TRIAGE, headers: true)
    .each do |row|
      health_question_responses =
        row.map do |question, answer|
          {
            question:,
            response: answer.present? ? "Yes" : "No",
            notes: answer.presence
          }
        end

      patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
      consent =
        FactoryBot.build(
          :consent_response,
          :given,
          %i[from_mum from_dad].sample,
          health_questions: health_question_responses,
          patient:,
          campaign: nil
        )
      patients_consent_triage << [patient, consent]
    end

  # cases to follow up on
  TO_FOLLOW_UP = <<~CSV.freeze
  triage notes,Does the child have any severe allergies that have led to an anaphylactic reaction,Does the child have any existing medical conditions?,Does the child take any regular medication?,Is there anything else we should know?
  "Spoke to child’s mum. Child completed leukaemia treatment 6 months ago. Need to speak to the consultant who treated her for a view on whether it’s safe to vaccinate. Dr Goehring, King’s College, 0208 734 5432.",,My daughter has just finished treatment for leukaemia. I don’t know if it’s safe for her to have the vaccination.,,
  Tried to get hold of parent to establish how severe the phobia is. Try again before vaccination session.,,,,My son is needle phobic.
  Tried to get hold of parent to find out where the pain is. Try again before vaccination session.,,My child has chronic pain due to a previous injury and struggles with discomfort daily,,
  Tried to get hold of parent to find out what the surgery was for. Try again before vaccination session.,,,,Our child recently had surgery and is still recovering. We want to make sure it’s safe for them to get the vaccine.
  CSV

  CSV
    .parse(TO_FOLLOW_UP, headers: true)
    .each do |row|
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

      patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
      consent =
        FactoryBot.build(
          :consent_response,
          :given,
          %i[from_mum from_dad].sample,
          health_questions: health_question_responses.compact,
          patient:,
          campaign: nil
        )
      triage = { notes: row["triage notes"], status: "needs_follow_up" }
      patients_consent_triage << [patient, consent, triage]
    end

  # cases that have already been triaged
  CSV
    .parse(TO_TRIAGE, headers: true)
    .each do |row|
      health_question_responses =
        row.map do |question, answer|
          {
            question:,
            response: answer.present? ? "Yes" : "No",
            notes: answer.presence
          }
        end

      patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
      consent =
        FactoryBot.build(
          :consent_response,
          :given,
          %i[from_mum from_dad].sample,
          health_questions: health_question_responses,
          patient:,
          campaign: nil
        )
      status = %i[ready_to_vaccinate do_not_vaccinate].sample
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
      patients_consent_triage << [patient, consent, triage]
    end

  patients_data =
    patients_consent_triage.map do |patient, consent, triage|
      consent_data =
        if consent
          {
            consent: consent.consent,
            reasonForRefusal: consent.reason_for_refusal,
            parentName: consent.parent_name,
            parentRelationship: consent.parent_relationship,
            parentEmail: consent.parent_email,
            parentPhone: consent.parent_phone,
            healthQuestionResponses: consent.health_questions,
            route: consent.route
          }
        end

      {
        firstName: patient.first_name,
        lastName: patient.last_name,
        dob: patient.dob.iso8601,
        nhsNumber: patient.nhs_number,
        consent: consent_data,
        triage:
      }
    end

  data = {
    id: "5M0",
    title: "HPV campaign at #{school_details[:name]}",
    location: school_details[:name],
    date: "2023-07-28T12:30",
    type: "HPV",
    vaccines: [hpv_vaccine],
    school: school_details,
    patients: patients_data
  }

  File.open(target_filename, "w") { |f| f << JSON.pretty_generate(data) }
end
# rubocop:enable Lint/ConstantDefinitionInBlock
