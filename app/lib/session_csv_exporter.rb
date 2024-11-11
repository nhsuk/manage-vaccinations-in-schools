# frozen_string_literal: true

class SessionCSVExporter
  def initialize(session)
    @session = session
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      patient_sessions.each do |patient_session|
        rows(patient_session:).each { |row| csv << row }
      end
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :session

  delegate :location, :organisation, to: :session

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
      BATCH_NUMBER
      BATCH_EXPIRY_DATE
      ANATOMICAL_SITE
      DOSE_SEQUENCE
      PERFORMING_PROFESSIONAL_EMAIL
    ].tap { |values| values << "CLINIC_NAME" if location.generic_clinic? }
  end

  def patient_sessions
    session
      .patient_sessions
      .includes(:patient, :vaccination_records)
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
    vaccination_records =
      patient_session.vaccination_records.order(:administered_at)

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        existing_row(vaccination_record:)
      end
    else
      [new_row(patient: patient_session.patient)]
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
      patient.date_of_birth.strftime("%Y%m%d"),
      patient.address_postcode,
      "", # DATE_OF_VACCINATION left blank for recording
      "", # TIME_OF_VACCINATION left blank for recording
      "", # VACCINATED left blank for recording
      "", # VACCINE_GIVEN left blank for recording
      "", # BATCH_NUMBER left blank for recording
      "", # BATCH_EXPIRY_DATE left blank for recording
      "", # ANATOMICAL_SITE left blank for recording
      1, # DOSE_SEQUENCE is 1 by default TODO: revisit this for other programmes
      "" # PERFORMING_PROFESSIONAL_EMAIL left blank for recording
    ].tap do |values|
      values << "" if location.generic_clinic? # CLINIC_NAME left blank for recording
    end
  end

  def existing_row(vaccination_record:)
    patient = vaccination_record.patient

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
      patient.date_of_birth.strftime("%Y%m%d"),
      patient.address_postcode,
      vaccination_record.administered_at&.strftime("%Y%m%d"),
      vaccination_record.administered_at&.strftime("%H:%M:%S"),
      vaccination_record.administered? ? "Y" : "N",
      (
        if vaccination_record.administered?
          vaccination_record.vaccine.nivs_name
        else
          ""
        end
      ),
      vaccination_record.administered? ? vaccination_record.batch&.name : "",
      (
        if vaccination_record.administered?
          vaccination_record.batch&.expiry&.strftime("%Y%m%d")
        else
          ""
        end
      ),
      delivery_site,
      vaccination_record.administered? ? vaccination_record.dose_sequence : "",
      (
        if vaccination_record.administered?
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
