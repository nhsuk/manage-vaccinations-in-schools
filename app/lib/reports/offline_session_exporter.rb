# frozen_string_literal: true

class Reports::OfflineSessionExporter
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
        sheet.add_row(headers)

        patient_sessions.each do |patient_session|
          rows(patient_session:).each do |row|
            sheet.add_row(row, types: row_types)
          end
        end
      end
  end

  def headers
    %w[
      ORGANISATION_CODE
      SCHOOL_URN
      SCHOOL_NAME
      CARE_SETTING
      NHS_NUMBER
      PERSON_FORENAME
      PERSON_SURNAME
      PERSON_GENDER_CODE
      PERSON_DOB
      PERSON_POSTCODE
      DATE_OF_VACCINATION
      TIME_OF_VACCINATION
      VACCINATED
      VACCINE_GIVEN
      REASON_NOT_VACCINATED
      BATCH_NUMBER
      BATCH_EXPIRY_DATE
      ANATOMICAL_SITE
      DOSE_SEQUENCE
      PERFORMING_PROFESSIONAL_EMAIL
    ].tap { |values| values << "CLINIC_NAME" if location.generic_clinic? }
  end

  def row_types
    types = [
      nil, # ORGANISATION_CODE
      nil, # SCHOOL_URN
      nil, # SCHOOL_NAME
      nil, # CARE_SETTING
      nil, # NHS_NUMBER
      nil, # PERSON_FORENAME
      nil, # PERSON_SURNAME
      nil, # PERSON_GENDER_CODE
      :date, # PERSON_DOB
      nil, # PERSON_POSTCODE
      :date, # DATE_OF_VACCINATION
      nil, # TIME_OF_VACCINATION
      nil, # VACCINATED
      nil, # VACCINE_GIVEN
      nil, # REASON_NOT_VACCINATED
      nil, # BATCH_NUMBER
      :date, # BATCH_EXPIRY_DATE
      nil, # ANATOMICAL_SITE
      nil, # DOSE_SEQUENCE
      nil # PERFORMING_PROFESSIONAL_EMAIL
    ]
    types << nil if location.generic_clinic? # CLINIC_NAME
    types
  end

  def patient_sessions
    session
      .patient_sessions
      .includes(
        patient: :school,
        vaccination_records: %i[batch performed_by_user vaccine]
      )
      .strict_loading
  end

  def care_setting
    location.school? ? "1" : "2"
  end

  def school_urn(patient:)
    if location.school?
      location.urn
    elsif patient.home_educated?
      "999999"
    else
      patient.school&.urn || "888888"
    end
  end

  def school_name(patient:)
    location.school? ? location.name : patient.school&.name || ""
  end

  def rows(patient_session:)
    patient = patient_session.patient

    vaccination_records =
      patient_session.vaccination_records.order(:administered_at)

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        existing_row(patient:, vaccination_record:)
      end
    else
      [new_row(patient:)]
    end
  end

  def new_row(patient:)
    [
      organisation.ods_code,
      school_urn(patient:),
      school_name(patient:),
      care_setting,
      patient.nhs_number,
      patient.given_name,
      patient.family_name,
      patient.gender_code.humanize,
      patient.date_of_birth,
      patient.address_postcode,
      "", # DATE_OF_VACCINATION left blank for recording
      "", # TIME_OF_VACCINATION left blank for recording
      "", # VACCINATED left blank for recording
      "", # VACCINE_GIVEN left blank for recording
      "", # REASON_NOT_VACCINATED left blank for recording
      "", # BATCH_NUMBER left blank for recording
      "", # BATCH_EXPIRY_DATE left blank for recording
      "", # ANATOMICAL_SITE left blank for recording
      1, # DOSE_SEQUENCE is 1 by default TODO: revisit this for other programmes
      "" # PERFORMING_PROFESSIONAL_EMAIL left blank for recording
    ].tap do |values|
      values << "" if location.generic_clinic? # CLINIC_NAME left blank for recording
    end
  end

  def existing_row(patient:, vaccination_record:)
    delivery_site =
      if vaccination_record.delivery_site
        ImmunisationImportRow::DELIVERY_SITES.key(
          vaccination_record.delivery_site
        )
      end

    [
      organisation.ods_code,
      school_urn(patient:),
      school_name(patient:),
      care_setting,
      patient.nhs_number,
      patient.given_name,
      patient.family_name,
      patient.gender_code.humanize,
      patient.date_of_birth,
      patient.address_postcode,
      vaccination_record.administered_at&.to_date,
      vaccination_record.administered_at&.strftime("%H:%M:%S"),
      vaccination_record.administered? ? "Y" : "N",
      (
        if vaccination_record.administered?
          vaccination_record.vaccine.nivs_name
        else
          ""
        end
      ),
      (
        if vaccination_record.reason.present?
          ImmunisationImportRow::REASONS.key(vaccination_record.reason.to_sym)
        else
          ""
        end
      ),
      (
        if vaccination_record.administered?
          vaccination_record.batch&.name
        else
          ""
        end
      ),
      (
        if vaccination_record.administered?
          vaccination_record.batch&.expiry
        else
          ""
        end
      ),
      delivery_site,
      vaccination_record.administered? ? vaccination_record.dose_sequence : "",
      (
        if vaccination_record.performed_by_user.present?
          vaccination_record.performed_by_user&.email
        else
          ""
        end
      )
    ].tap do |values|
      values << vaccination_record.location_name if location.generic_clinic?
    end
  end
end
