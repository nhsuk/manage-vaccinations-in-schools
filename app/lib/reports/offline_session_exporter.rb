# frozen_string_literal: true

class Reports::OfflineSessionExporter
  include Reports::ExportFormatters

  def initialize(session)
    @session = session
  end

  def call
    Axlsx::Package
      .new { |package| add_vaccinations_sheet(package) }
      .to_stream
      .read
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :session

  delegate :location, :organisation, to: :session

  def add_vaccinations_sheet(package)
    package
      .workbook
      .add_worksheet(name: "Vaccinations") do |sheet|
        sheet.add_row(headers_and_types.keys)

        patient_sessions.each do |patient_session|
          rows(patient_session:).each do |row|
            sheet.add_row(row, types: headers_and_types.values)
          end
        end
      end
  end

  def headers_and_types
    {
      "ORGANISATION_CODE" => nil,
      "SCHOOL_URN" => nil,
      "SCHOOL_NAME" => nil,
      "CARE_SETTING" => nil,
      "CLINIC_NAME" => nil,
      "PERSON_FORENAME" => nil,
      "PERSON_SURNAME" => nil,
      "PERSON_DOB" => :date,
      "YEAR_GROUP" => nil,
      "PERSON_GENDER_CODE" => nil,
      "PERSON_POSTCODE" => nil,
      "NHS_NUMBER" => nil,
      "CONSENT_STATUS" => nil,
      "CONSENT_DETAILS" => nil,
      "HEALTH_QUESTION_ANSWERS" => nil,
      "TRIAGE_STATUS" => nil,
      "TRIAGED_BY" => nil,
      "TRIAGE_DATE" => :date,
      "TRIAGE_NOTES" => nil,
      "GILLICK_STATUS" => nil,
      "GILLICK_ASSESSMENT_DATE" => :date,
      "GILLICK_ASSESSED_BY" => nil,
      "GILLICK_ASSESSMENT_NOTES" => nil,
      "VACCINATED" => nil,
      "DATE_OF_VACCINATION" => :date,
      "TIME_OF_VACCINATION" => nil,
      "VACCINE_GIVEN" => nil,
      "PERFORMING_PROFESSIONAL_EMAIL" => nil,
      "BATCH_NUMBER" => nil,
      "BATCH_EXPIRY_DATE" => :date,
      "ANATOMICAL_SITE" => nil,
      "DOSE_SEQUENCE" => nil,
      "REASON_NOT_VACCINATED" => nil
    }.tap { |hash| hash.delete("CLINIC_NAME") unless location.generic_clinic? }
  end

  def patient_sessions
    session
      .patient_sessions
      .includes(
        patient: %i[cohort school],
        consents: [:patient, { parent: :parent_relationships }],
        gillick_assessment: :performed_by,
        triages: :performed_by,
        vaccination_records: %i[batch performed_by_user vaccine]
      )
      .strict_loading
  end

  def rows(patient_session:)
    consents = patient_session.latest_consents
    gillick_assessment = patient_session.gillick_assessment
    patient = patient_session.patient
    triage = patient_session.latest_triage

    vaccination_records =
      patient_session.vaccination_records.order(:administered_at)

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        existing_row(
          patient:,
          consents:,
          gillick_assessment:,
          triage:,
          vaccination_record:
        )
      end
    else
      [new_row(patient:, consents:, gillick_assessment:, triage:)]
    end
  end

  def new_row(patient:, consents:, gillick_assessment:, triage:)
    [
      organisation.ods_code,
      school_urn(location:, patient:),
      school_name(location:, patient:),
      care_setting(location:),
      patient.given_name,
      patient.family_name,
      patient.date_of_birth,
      patient.year_group,
      patient.gender_code.humanize,
      patient.address_postcode,
      patient.nhs_number,
      consents.first&.response&.humanize,
      consent_details(consents:),
      health_question_answers(consents:),
      triage&.status&.humanize,
      triage&.performed_by&.full_name,
      triage&.created_at,
      triage&.notes,
      gillick_status(gillick_assessment:),
      gillick_assessment&.updated_at,
      gillick_assessment&.performed_by&.full_name,
      gillick_assessment&.notes,
      "", # VACCINATED left blank for recording
      "", # DATE_OF_VACCINATION left blank for recording
      "", # TIME_OF_VACCINATION left blank for recording
      "", # VACCINE_GIVEN left blank for recording
      "", # PERFORMING_PROFESSIONAL_EMAIL left blank for recording
      "", # BATCH_NUMBER left blank for recording
      "", # BATCH_EXPIRY_DATE left blank for recording
      "", # ANATOMICAL_SITE left blank for recording
      1, # DOSE_SEQUENCE is 1 by default TODO: revisit this for other programmes
      "" # REASON_NOT_VACCINATED left blank for recording
    ].tap do |values|
      values.insert(4, "") if location.generic_clinic? # CLINIC_NAME left blank for recording
    end
  end

  def existing_row(
    patient:,
    consents:,
    gillick_assessment:,
    triage:,
    vaccination_record:
  )
    [
      organisation.ods_code,
      school_urn(location:, patient:),
      school_name(location:, patient:),
      care_setting(location:),
      patient.given_name,
      patient.family_name,
      patient.date_of_birth,
      patient.year_group,
      patient.gender_code.humanize,
      patient.address_postcode,
      patient.nhs_number,
      consents.first&.response&.humanize,
      consent_details(consents:),
      health_question_answers(consents:),
      triage&.status&.humanize,
      triage&.performed_by&.full_name,
      triage&.created_at,
      triage&.notes,
      gillick_status(gillick_assessment:),
      gillick_assessment&.updated_at,
      gillick_assessment&.performed_by&.full_name,
      gillick_assessment&.notes,
      vaccinated(vaccination_record:),
      vaccination_record.administered_at&.to_date,
      vaccination_record.administered_at&.strftime("%H:%M:%S"),
      vaccination_record.vaccine&.nivs_name,
      vaccination_record.performed_by_user&.email,
      vaccination_record.batch&.name,
      vaccination_record.batch&.expiry,
      anatomical_site(vaccination_record:),
      dose_sequence(vaccination_record:),
      reason_not_vaccinated(vaccination_record:)
    ].tap do |values|
      if location.generic_clinic?
        values.insert(4, vaccination_record.location_name)
      end
    end
  end
end
