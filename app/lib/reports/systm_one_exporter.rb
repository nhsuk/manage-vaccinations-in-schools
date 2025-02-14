# frozen_string_literal: true

class Reports::SystmOneExporter
  def initialize(organisation:, programme:, start_date:, end_date:)
    @organisation = organisation
    @programme = programme
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      programme
        .sessions
        .where(organisation:)
        .find_each do |session|
          patient_sessions_for_session(session).each do |patient_session|
            rows(patient_session:).each { |row| csv << row }
          end
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
    [
      "Practice code",
      "NHS number",
      "Surname",
      "Middle name",
      "Forename",
      "Gender",
      "Date of Birth",
      "House name",
      "House number and road",
      "Town",
      "Vaccination",
      "Part",
      "Admin date",
      "Batch number",
      "Expiry date",
      "Dose",
      "Reason",
      "Site",
      "Method",
      "Notes"
    ]
  end

  def patient_sessions_for_session(session)
    scope =
      session
        .patient_sessions
        .includes(
          :location,
          :vaccination_records,
          consents: %i[parent patient],
          patient: :school
        )
        .where.not(vaccination_records: { id: nil })
        .merge(VaccinationRecord.administered)

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

  def rows(patient_session:)
    patient = patient_session.patient
    vaccination_records =
      patient_session.vaccination_records.administered.order(:performed_at)

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        existing_row(patient:, patient_session:, vaccination_record:)
      end
    end
  end

  def existing_row(patient:, vaccination_record:)
    batch = vaccination_record.batch

    [
      organisation.ods_code, # Practice code
      patient.nhs_number, # NHS number
      patient.family_name, # Surname
      "", # Middle name (not stored)
      patient.given_name, # Forename
      gender_code(patient.gender_code), # Gender
      patient.date_of_birth.to_fs(:uk_short),
      patient.address_line_1, # House name
      patient.address_line_2, # House number and road
      patient.address_town, # Town
      vaccination_record.vaccine.nivs_name, # Vaccination
      vaccination_record.dose_sequence, # Part
      vaccination_record.performed_at.to_fs(:uk_short), # Admin date
      batch&.name, # Batch number
      batch&.expiry&.to_fs(:uk_short), # Expiry date
      vaccination_record.dose_volume_ml, # Dose
      "", # Reason (not specified)
      vaccination_record.delivery_site, # Site
      vaccination_record.delivery_method, # Method
      vaccination_record.notes # Notes
    ]
  end

  def gender_code(code)
    case code
    when "not_known"
      "Not known"
    when "not_specified"
      "Not specified"
    else
      code.capitalize
    end
  end
end
