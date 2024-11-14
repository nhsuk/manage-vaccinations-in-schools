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
      CARE_SETTING
      CLINIC_NAME
      PERSON_FORENAME
      PERSON_SURNAME
      PERSON_DOB
      YEAR_GROUP
      PERSON_GENDER_CODE
      PERSON_POSTCODE
      NHS_NUMBER
      CONSENT_STATUS
      CONSENT_DETAILS
      HEALTH_QUESTION_ANSWERS
      TRIAGE_STATUS
      TRIAGED_BY
      TRIAGE_DATE
      TRIAGE_NOTES
      GILLICK_STATUS
      GILLICK_ASSESSMENT_DATE
      GILLICK_ASSESSED_BY
      GILLICK_ASSESSMENT_NOTES
      VACCINATED
      DATE_OF_VACCINATION
      TIME_OF_VACCINATION
      VACCINE_GIVEN
      PERFORMING_PROFESSIONAL_EMAIL
      PERFORMING_PROFESSIONAL_FORENAME
      PERFORMING_PROFESSIONAL_SURNAME
      BATCH_NUMBER
      BATCH_EXPIRY_DATE
      ANATOMICAL_SITE
      ROUTE_OF_VACCINATION
      DOSE_SEQUENCE
      REASON_NOT_GIVEN
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
          patient_session: {
            patient: %i[cohort school],
            consents: %i[parent patient],
            gillick_assessment: :performed_by,
            triages: :performed_by
          }
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
    patient_session = vaccination_record.patient_session
    consents = patient_session.latest_consents
    gillick_assessment = patient_session.gillick_assessment
    patient = patient_session.patient
    triage = patient_session.latest_triage
    location = vaccination_record.location

    [
      organisation.ods_code,
      school_urn(location, patient),
      school_name(location, patient, vaccination_record),
      location.school? ? "1" : "2",
      clinic_name(location, vaccination_record),
      patient.given_name,
      patient.family_name,
      patient.date_of_birth.strftime("%Y%m%d"),
      patient.year_group || "",
      patient.gender_code.humanize,
      patient.address_postcode,
      patient.nhs_number,
      consents.first&.response&.humanize || "",
      consent_details(consents),
      health_question_answers(consents),
      triage&.status&.humanize || "",
      triage&.performed_by&.full_name || "",
      triage&.updated_at&.strftime("%Y%m%d") || "",
      triage&.notes || "",
      if gillick_assessment&.gillick_competent?
        "Gillick competent"
      elsif gillick_assessment&.gillick_competent? == false
        "Not Gillick competent"
      else
        ""
      end,
      gillick_assessment&.updated_at&.strftime("%Y%m%d") || "",
      gillick_assessment&.performed_by&.full_name || "",
      gillick_assessment&.notes || "",
      vaccination_record.administered? ? "Y" : "N",
      vaccination_record.administered_at&.strftime("%Y%m%d"),
      vaccination_record.administered_at&.strftime("%H:%M:%S"),
      vaccination_record.vaccine&.nivs_name || "",
      vaccination_record.performed_by_user&.email || "",
      vaccination_record.performed_by&.given_name || "",
      vaccination_record.performed_by&.family_name || "",
      vaccination_record.batch&.name || "",
      vaccination_record.batch&.expiry&.strftime("%Y%m%d") || "",
      vaccination_record.delivery_site&.humanize || "",
      vaccination_record.delivery_method&.humanize || "",
      vaccination_record.dose_sequence,
      (
        if vaccination_record.reason.present?
          ImmunisationImportRow::REASONS.key(vaccination_record.reason.to_sym)
        else
          ""
        end
      )
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

  def consent_details(consents)
    values =
      consents.map do |consent|
        "#{consent.response.humanize} by #{consent.name} at #{consent.recorded_at}"
      end

    values.join(", ")
  end

  def health_question_answers(consents)
    values =
      consents.flat_map do |consent|
        consent.health_answers.map do |health_answer|
          "#{health_answer.question} - #{health_answer.response}"
        end
      end

    values.join(", ")
  end
end
