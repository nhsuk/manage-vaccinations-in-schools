#!frozen_string_literal: true
# frozen_string_literal: true

describe PipelineStats do
  subject(:diagram) { instance.render }

  let(:instance) { described_class.new }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }
  let(:flu_programme) { Programme.flu&.first || create(:programme, :flu) }

  def create_consent_requests_for_patients(patients, count, session)
    return if patients.empty?
    return if count.blank?

    count.times do
      patient = patients.sample
      create(:consent_notification, :request, session:, patient:)
      patients -= [patient]
    end
  end

  def create_consents_for_patients(
    patients,
    count,
    response,
    organisation,
    programme
  )
    return if patients.empty?
    return if count.blank?

    count.times do
      patient = patients.sample
      create(:consent, response, patient:, organisation:, programme:)
      patients -= [patient]
    end
    patients
  end

  before do
    [
      organisation,
      create(:organisation, programmes: [flu_programme])
    ].each do |organisation|
      session =
        create(:session, organisation:, programmes: organisation.programmes)
      cohort_import = create(:cohort_import, organisation:)
      class_import = create(:class_import, organisation:, session:)
      programme = organisation.programmes.first

      counts = {
        cohort_import: {
          patients: 4,
          consent_notifications: 4,
          consents: {
            given: 1,
            refused: 1,
            not_provided: 1
          }
        },
        cohort_and_class_import: {
          patients: 2,
          consent_notifications: 2,
          consents: {
          }
        },
        class_import: {
          patients: 2,
          consent_notifications: 2,
          consents: {
          }
        }
      }

      cohort_import_patients =
        create_list(
          :patient,
          counts[:cohort_import][:patients],
          organisation:,
          session:,
          year_group: 10,
          cohort_imports: [cohort_import]
        )
      create_consent_requests_for_patients(
        cohort_import_patients,
        counts[:cohort_import][:consent_notifications],
        session
      )
      available_patients = cohort_import_patients.dup
      counts[:cohort_import][:consents].each do |response, count|
        available_patients =
          create_consents_for_patients(
            available_patients,
            count,
            response,
            organisation,
            programme
          )
      end

      cohort_and_class_import_patients =
        create_list(
          :patient,
          counts[:cohort_and_class_import][:patients],
          organisation:,
          session:,
          year_group: 10,
          cohort_imports: [cohort_import],
          class_imports: [class_import]
        )
      create_consent_requests_for_patients(
        cohort_and_class_import_patients,
        counts[:cohort_and_class_import][:consent_notifications],
        session
      )
      available_patients = cohort_and_class_import_patients.dup
      counts[:cohort_and_class_import][:consents].each do |response, count|
        available_patients =
          create_consents_for_patients(
            available_patients,
            count,
            response,
            organisation,
            programme
          )
      end

      class_import_patients =
        create_list(
          :patient,
          counts[:class_import][:patients],
          organisation:,
          session:,
          year_group: 10,
          class_imports: [class_import]
        )
      create_consent_requests_for_patients(
        class_import_patients,
        counts[:class_import][:consent_notifications],
        session
      )
      available_patients = class_import_patients.dup
      counts[:class_import][:consents].each do |response, count|
        available_patients =
          create_consents_for_patients(
            available_patients,
            count,
            response,
            organisation,
            programme
          )
      end

      create(:patient, organisation:, session:, year_group: 10)
    end
  end

  it "produces stats for all organisations and programmes" do
    expect(diagram).to eq <<~DIAGRAM
      sankey-beta
      Cohort Upload,Uploaded Patients,12
      Class Upload,Uploaded Patients,4
      Uploaded Patients,Consent Requests Sent,16
      Consent Requests Sent,Consent Responses,4
      Consent Responses,Consent Given,2
      Consent Responses,Consent Refused,2
      Consent Responses,Without Consent Response,12
    DIAGRAM
  end

  context "given an organisation" do
    let(:instance) { described_class.new(organisations: [organisation]) }

    it "produces stats for the given organisation and all programmes" do
      expect(diagram).to eq <<~DIAGRAM
        sankey-beta
        Cohort Upload,Uploaded Patients,6
        Class Upload,Uploaded Patients,2
        Uploaded Patients,Consent Requests Sent,8
        Consent Requests Sent,Consent Responses,2
        Consent Responses,Consent Given,1
        Consent Responses,Consent Refused,1
        Consent Responses,Without Consent Response,6
      DIAGRAM
    end
  end

  context "given a programme" do
    let(:instance) { described_class.new(programmes: [flu_programme]) }

    it "produces stats for all organisations but only that programme" do
      expect(diagram).to eq <<~DIAGRAM
        sankey-beta
        Cohort Upload,Uploaded Patients,6
        Class Upload,Uploaded Patients,2
        Uploaded Patients,Consent Requests Sent,8
        Consent Requests Sent,Consent Responses,2
        Consent Responses,Consent Given,1
        Consent Responses,Consent Refused,1
        Consent Responses,Without Consent Response,6
      DIAGRAM
    end
  end
end
