# frozen_string_literal: true

class Reports::OfflineSessionExporter
  include Reports::ExportFormatters

  def initialize(session)
    @session = session
  end

  def call
    sheet.add_row(headers_and_types.keys)
    patient_sessions.each { |patient_session| add_rows(patient_session:) }
    package.to_stream.read
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :session

  delegate :location, :organisation, to: :session

  def package
    @package ||= Axlsx::Package.new(use_shared_strings: true)
  end

  delegate :workbook, to: :package

  def sheet
    @sheet ||= workbook.add_worksheet(name: "Vaccinations")
  end

  def date_style
    @date_style ||= workbook.styles.add_style(format_code: "dd/mm/yyyy")
  end

  def wrap_style
    @wrap_style ||= workbook.styles.add_style(alignment: { wrap_text: true })
  end

  def strike_style
    @strike_style ||= workbook.styles.add_style(strike: true)
  end

  def headers_and_types
    @headers_and_types ||=
      {
        "ORGANISATION_CODE" => :string,
        "SCHOOL_URN" => :string,
        "SCHOOL_NAME" => :string,
        "CARE_SETTING" => :integer,
        "CLINIC_NAME" => :string,
        "PERSON_FORENAME" => :string,
        "PERSON_SURNAME" => :string,
        "PERSON_DOB" => :date,
        "YEAR_GROUP" => nil, # should be integer, but that converts nil to 0
        "PERSON_GENDER_CODE" => :string,
        "PERSON_ADDRESS_LINE_1" => :string,
        "PERSON_POSTCODE" => :string,
        "NHS_NUMBER" => :string,
        "CONSENT_STATUS" => :string,
        "CONSENT_DETAILS" => :string,
        "HEALTH_QUESTION_ANSWERS" => :string,
        "TRIAGE_STATUS" => :string,
        "TRIAGED_BY" => :string,
        "TRIAGE_DATE" => :date,
        "TRIAGE_NOTES" => :string,
        "GILLICK_STATUS" => :string,
        "GILLICK_ASSESSMENT_DATE" => :date,
        "GILLICK_ASSESSED_BY" => :string,
        "GILLICK_ASSESSMENT_NOTES" => :string,
        "VACCINATED" => :string,
        "DATE_OF_VACCINATION" => :date,
        "TIME_OF_VACCINATION" => :string,
        "PROGRAMME_NAME" => :string,
        "VACCINE_GIVEN" => :string,
        "PERFORMING_PROFESSIONAL_EMAIL" => :string,
        "BATCH_NUMBER" => :string,
        "BATCH_EXPIRY_DATE" => :date,
        "ANATOMICAL_SITE" => :string,
        "DOSE_SEQUENCE" => nil, # should be integer, but that converts nil to 0
        "REASON_NOT_VACCINATED" => :string,
        "NOTES" => :string,
        "UUID" => :string
      }.tap do |hash|
        hash.delete("CLINIC_NAME") unless location.generic_clinic?
      end
  end

  def row_types
    @row_types ||= headers_and_types.values
  end

  def row_style
    @row_style ||=
      headers_and_types.map do |header, type|
        if type == :date
          date_style
        elsif header == "HEALTH_QUESTION_ANSWERS"
          wrap_style
        end
      end
  end

  def row_style_with_nhs_number_strike
    @row_style_with_nhs_number_strike ||=
      row_style.dup.tap do |style|
        style[headers_and_types.keys.index("NHS_NUMBER")] = strike_style
      end
  end

  def patient_sessions
    session
      .patient_sessions
      .includes(
        patient: %i[cohort school],
        consents: [:patient, { parent: :parent_relationships }],
        gillick_assessments: :performed_by,
        triages: :performed_by,
        vaccination_records: %i[batch performed_by_user vaccine]
      )
      .strict_loading
  end

  def add_rows(patient_session:)
    consents = patient_session.latest_consents
    gillick_assessment = patient_session.latest_gillick_assessment
    patient = patient_session.patient
    triage = patient_session.latest_triage

    vaccination_records =
      patient_session.vaccination_records.order(:performed_at)

    style =
      (patient.invalidated? ? row_style_with_nhs_number_strike : row_style)

    if vaccination_records.any?
      vaccination_records.each do |vaccination_record|
        sheet.add_row(
          existing_row(
            patient:,
            consents:,
            gillick_assessment:,
            triage:,
            vaccination_record:
          ),
          types: row_types,
          style:
        )
      end
    elsif !patient_session.consent_refused?
      session.programmes.each do |programme|
        sheet.add_row(
          new_row(
            patient:,
            consents:,
            gillick_assessment:,
            triage:,
            programme:
          ),
          types: row_types,
          style:
        )
      end
    end
  end

  def new_row(patient:, consents:, gillick_assessment:, triage:, programme:)
    (
      patient_values(patient:, consents:, gillick_assessment:, triage:) +
        [
          "", # VACCINATED left blank for recording
          "", # DATE_OF_VACCINATION left blank for recording
          "", # TIME_OF_VACCINATION left blank for recording
          programme.name,
          "", # VACCINE_GIVEN left blank for recording
          "", # PERFORMING_PROFESSIONAL_EMAIL left blank for recording
          "", # BATCH_NUMBER left blank for recording
          "", # BATCH_EXPIRY_DATE left blank for recording
          "", # ANATOMICAL_SITE left blank for recording
          1, # DOSE_SEQUENCE is 1 by default TODO: revisit this for other programmes
          "", # REASON_NOT_VACCINATED left blank for recording
          "", # NOTES left blank for recording
          "" # UUID left blank as new record
        ]
    ).tap do |values|
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
    (
      patient_values(patient:, consents:, gillick_assessment:, triage:) +
        [
          vaccinated(vaccination_record:),
          vaccination_record.performed_at.to_date,
          vaccination_record.performed_at.strftime("%H:%M:%S"),
          vaccination_record.programme.name,
          vaccination_record.vaccine&.nivs_name,
          vaccination_record.performed_by_user&.email,
          vaccination_record.batch&.name,
          vaccination_record.batch&.expiry,
          anatomical_site(vaccination_record:),
          dose_sequence(vaccination_record:),
          reason_not_vaccinated(vaccination_record:),
          vaccination_record.notes,
          vaccination_record.uuid
        ]
    ).tap do |values|
      if location.generic_clinic?
        values.insert(4, vaccination_record.location_name)
      end
    end
  end

  def patient_values(patient:, consents:, gillick_assessment:, triage:)
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
      patient.restricted? ? "" : patient.address_line_1,
      patient.restricted? ? "" : patient.address_postcode,
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
      gillick_assessment&.notes
    ]
  end
end
