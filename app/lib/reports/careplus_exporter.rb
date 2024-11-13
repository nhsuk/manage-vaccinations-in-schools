# frozen_string_literal: true

class Reports::CareplusExporter
  def initialize(programme:, start_date:, end_date:)
    @programme = programme
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate do |csv|
      csv << headers
      programme.sessions.each do |session|
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

  attr_reader :programme, :start_date, :end_date

  def headers
    [
      "NHS Number",
      "Surname",
      "Forename",
      "Date of Birth",
      "Address Line 1",
      "Person Giving Consent",
      "Ethnicity",
      "Date Attended",
      "Time Attended",
      "Venue Type",
      "Venue Code",
      "Staff Type",
      "Staff Code",
      "Attended",
      "Reason Not Attended",
      "Suspension End Date",
      *vaccine_columns(1),
      *vaccine_columns(2),
      *vaccine_columns(3),
      *vaccine_columns(4),
      *vaccine_columns(5)
    ]
  end

  def vaccine_columns(number)
    [
      "Vaccine #{number}",
      "Dose #{number}",
      "Reason Not Given #{number}",
      "Site #{number}",
      "Manufacturer #{number}",
      "Batch No #{number}"
    ]
  end

  def patient_sessions_for_session(session)
    scope =
      session
        .patient_sessions
        .includes(:vaccination_records, consents: :parent, patient: :school)
        .where.not(vaccination_records: { id: nil })
        .merge(VaccinationRecord.administered)

    if start_date.present?
      scope =
        scope.where(
          "vaccination_records.administered_at >= ?",
          start_date.beginning_of_day
        )
    end

    if end_date.present?
      scope =
        scope.where(
          "vaccination_records.administered_at <= ?",
          end_date.end_of_day
        )
    end

    scope.strict_loading
  end

  def rows(patient_session:)
    patient = patient_session.patient
    vaccination_records =
      patient_session.vaccination_records.order(:administered_at)

    if vaccination_records.any?
      [existing_row(patient:, patient_session:, vaccination_records:)]
    end
  end

  def existing_row(patient:, patient_session:, vaccination_records:)
    first_vaccination = vaccination_records.first

    [
      patient.nhs_number,
      patient.family_name,
      patient.given_name,
      patient.date_of_birth.strftime("%d/%m/%Y"),
      patient.address_line_1,
      patient_session.latest_consents.first&.name || "",
      99, # Ethnicity, 99 is "Not known"
      first_vaccination.administered_at.strftime("%d/%m/%Y"),
      first_vaccination.administered_at.strftime("%H:%M"),
      "SC", # Venue Type
      "School", # Venue Code
      "SN", # Staff Type
      "School Nurse", # Staff Code
      "Y", # Attended; Did not attends do not get recorded on GP systems
      "", # Reason Not Attended; Always blank
      "", # Suspension End Date; Not sure what this is, leaving blank
      *vaccine_fields(vaccination_records, 0),
      *vaccine_fields(vaccination_records, 1),
      *vaccine_fields(vaccination_records, 2),
      *vaccine_fields(vaccination_records, 3),
      *vaccine_fields(vaccination_records, 4)
    ]
  end

  def blank_vaccine_fields
    ["", "", "", "", "", ""]
  end

  def vaccine_fields(vaccination_records, index)
    record = vaccination_records[index]
    return blank_vaccine_fields unless record

    [
      record.vaccine.snomed_product_code, # Vaccine X
      "", # Dose X field; Not sure, documentation says this is derived later?
      VaccinationRecord.human_enum_name(:reason, record.reason), # Reason Not Given X
      record.delivery_site, # Site X; Coded value, but we don't know the codes yet
      record.vaccine.manufacturer, # Manufacturer X
      record.batch.name # Batch No X
    ]
  end
end
