# frozen_string_literal: true

class Reports::ProgrammeVaccinationsExporter
  def initialize(organisation:, programme:, start_date:, end_date:)
    @organisation = organisation
    @programme = programme
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      vaccination_records.each do |vaccination_record|
        csv << row(vaccination_record:)
      end
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :organisation, :programme, :start_date, :end_date

  def headers
    %w[
      ORGANISATION_CODE
      SCHOOL_URN
      SCHOOL_NAME
      CLINIC_NAME
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
      PERFORMING_PROFESSIONAL_FORENAME
      PERFORMING_PROFESSIONAL_SURNAME
    ]
  end

  def vaccination_records
    scope =
      programme
        .vaccination_records
        .joins(:organisation)
        .where(organisations: { id: organisation.id })
        .includes(
          :batch,
          :location,
          :performed_by_user,
          :vaccine,
          patient: :school
        )

    if start_date.present?
      scope = scope.where("administered_at >= ?", start_date.beginning_of_day)
    end

    if end_date.present?
      scope = scope.where("administered_at <= ?", end_date.end_of_day)
    end

    scope.strict_loading
  end

  def row(vaccination_record:)
    patient = vaccination_record.patient
    location = vaccination_record.location

    [
      organisation.ods_code,
      school_urn(location, patient),
      school_name(location, patient, vaccination_record),
      clinic_name(location, vaccination_record),
      location.school? ? "1" : "2",
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
          vaccination_record.batch&.expiry&.strftime("%Y%m%d")
        else
          ""
        end
      ),
      (
        if vaccination_record.delivery_site
          ImmunisationImportRow::DELIVERY_SITES.key(
            vaccination_record.delivery_site
          )
        else
          ""
        end
      ),
      vaccination_record.administered? ? vaccination_record.dose_sequence : "",
      vaccination_record.performed_by_user&.email || "",
      vaccination_record.performed_by&.given_name || "",
      vaccination_record.performed_by&.family_name || ""
    ]
  end

  def school_urn(location, patient)
    if location.school?
      location.urn
    elsif patient.home_educated?
      "999999"
    else
      patient.school&.urn || "888888"
    end
  end

  def school_name(location, patient, _vaccination_record)
    location.school? ? location.name : patient.school&.name || ""
  end

  def clinic_name(location, vaccination_record)
    location.school? ? "" : vaccination_record.location_name
  end
end
