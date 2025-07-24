# frozen_string_literal: true

class Reports::ProgrammeVaccinationsExporter
  include Reports::ExportFormatters

  def initialize(organisation:, programme:, start_date:, end_date:)
    @organisation = organisation
    @programme = programme
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      vaccination_records.find_each do |vaccination_record|
        csv << row(vaccination_record:)
      end
    end
  end

  def self.call(...) = new(...).call

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
      PERSON_DATE_OF_BIRTH
      PERSON_DATE_OF_DEATH
      YEAR_GROUP
      PERSON_GENDER_CODE
      PERSON_ADDRESS_LINE_1
      PERSON_POSTCODE
      NHS_NUMBER
      NHS_NUMBER_STATUS_CODE
      GP_ORGANISATION_CODE
      GP_NAME
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
      GILLICK_NOTIFY_PARENTS
      VACCINATED
      DATE_OF_VACCINATION
      TIME_OF_VACCINATION
      PROGRAMME_NAME
      VACCINE_GIVEN
      PERFORMING_PROFESSIONAL_EMAIL
      PERFORMING_PROFESSIONAL_FORENAME
      PERFORMING_PROFESSIONAL_SURNAME
      BATCH_NUMBER
      BATCH_EXPIRY_DATE
      ANATOMICAL_SITE
      ROUTE_OF_VACCINATION
      DOSE_SEQUENCE
      DOSE_VOLUME
      REASON_NOT_VACCINATED
      LOCAL_PATIENT_ID
      SNOMED_PROCEDURE_CODE
      REASON_FOR_INCLUSION
      RECORD_CREATED
      RECORD_UPDATED
    ]
  end

  def vaccination_records
    scope =
      organisation
        .vaccination_records
        .where(programme:)
        .includes(
          :batch,
          :location,
          :performed_by_user,
          :vaccine,
          patient: %i[consent_statuses gp_practice school]
        )

    if start_date.present?
      scope =
        scope.where(
          "vaccination_records.created_at >= ?",
          start_date.beginning_of_day
        ).or(
          scope.where(
            "vaccination_records.updated_at >= ?",
            start_date.beginning_of_day
          )
        )
    end

    if end_date.present?
      scope =
        scope.where(
          "vaccination_records.created_at <= ?",
          end_date.end_of_day
        ).or(
          scope.where(
            "vaccination_records.updated_at <= ?",
            end_date.end_of_day
          )
        )
    end

    scope
  end

  def consents
    @consents ||=
      Consent
        .where(patient_id: vaccination_records.select(:patient_id), programme:)
        .not_invalidated
        .includes(:parent, :patient)
        .group_by(&:patient_id)
        .transform_values do
          ConsentGrouper.call(it, programme_id: programme.id)
        end
  end

  def gillick_assessments
    @gillick_assessments ||=
      GillickAssessment
        .select(
          "DISTINCT ON (patient_session_id) gillick_assessments.*, patient_id, session_id"
        )
        .joins(:patient_session)
        .where(
          patient_sessions: {
            patient_id: vaccination_records.select(:patient_id),
            session_id: vaccination_records.select(:session_id)
          },
          programme:
        )
        .order(:patient_session_id, created_at: :desc)
        .includes(:performed_by)
        .group_by(&:patient_id)
        .transform_values do
          it.group_by(&:session_id).transform_values(&:first)
        end
  end

  def triages
    @triages ||=
      Triage
        .select("DISTINCT ON (patient_id) triage.*")
        .where(patient_id: vaccination_records.select(:patient_id), programme:)
        .not_invalidated
        .order(:patient_id, created_at: :desc)
        .includes(:performed_by)
        .group_by(&:patient_id)
        .transform_values(&:first)
  end

  def row(vaccination_record:)
    location = vaccination_record.location
    patient = vaccination_record.patient
    session = vaccination_record.session
    vaccine = vaccination_record.vaccine

    grouped_consents = consents.fetch(patient.id, [])
    triage = triages[patient.id]
    gillick_assessment = gillick_assessments.dig(patient.id, session.id)

    [
      organisation.ods_code,
      school_urn(location:, patient:),
      school_name(location:, patient:),
      care_setting(location:),
      clinic_name(location:, vaccination_record:),
      patient.given_name,
      patient.family_name,
      patient.date_of_birth.iso8601,
      patient.date_of_death&.iso8601 || "",
      patient.year_group || "",
      patient.gender_code.humanize,
      patient.restricted? ? "" : patient.address_line_1,
      patient.restricted? ? "" : patient.address_postcode,
      patient.nhs_number,
      nhs_number_status_code(patient:),
      patient.gp_practice&.ods_code || "",
      patient.gp_practice&.name || "",
      consent_status(patient:, programme:),
      consent_details(consents: grouped_consents),
      health_question_answers(consents: grouped_consents),
      triage&.status&.humanize || "",
      triage&.performed_by&.full_name || "",
      triage&.updated_at&.to_date&.iso8601 || "",
      triage&.notes || "",
      gillick_status(gillick_assessment:),
      gillick_assessment&.created_at&.to_date&.iso8601 || "",
      gillick_assessment&.performed_by&.full_name || "",
      gillick_assessment&.notes || "",
      gillick_notify_parents(patient:, gillick_assessment:),
      vaccinated(vaccination_record:),
      vaccination_record.performed_at.to_date.iso8601,
      vaccination_record.performed_at.strftime("%H:%M:%S"),
      programme.name,
      vaccine&.nivs_name || "",
      vaccination_record.performed_by_user&.email || "",
      vaccination_record.performed_by&.given_name || "",
      vaccination_record.performed_by&.family_name || "",
      vaccination_record.batch&.name || "",
      vaccination_record.batch&.expiry&.iso8601 || "",
      anatomical_site(vaccination_record:),
      route_of_vaccination(vaccination_record:),
      dose_sequence(vaccination_record:),
      vaccination_record.dose_volume_ml,
      reason_not_vaccinated(vaccination_record:),
      patient.id,
      vaccination_record.snomed_procedure_code,
      reason_for_inclusion(vaccination_record:),
      record_created_at(vaccination_record:),
      record_updated_at(vaccination_record:)
    ]
  end

  def nhs_number_status_code(patient:)
    present = patient.nhs_number.present?
    verified = patient.updated_from_pds_at.present?

    if present && verified
      "01" # Number present and verified
    elsif present
      "02" # Number present but not traced
    else
      "03" # Trace required
    end
  end

  def gillick_notify_parents(patient:, gillick_assessment:)
    return "" if gillick_assessment.nil?

    if (consent = consents[patient.id]&.find(&:via_self_consent?))
      consent.notify_parents ? "Y" : "N"
    else
      ""
    end
  end

  def reason_for_inclusion(vaccination_record:)
    if start_date.present? && vaccination_record.created_at < start_date
      return "updated"
    end

    "new"
  end

  def record_created_at(vaccination_record:)
    vaccination_record.created_at.iso8601
  end

  def record_updated_at(vaccination_record:)
    return "" if vaccination_record.created_at == vaccination_record.updated_at

    vaccination_record.updated_at.iso8601
  end
end
