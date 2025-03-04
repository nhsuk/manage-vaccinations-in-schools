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
      "Postcode",
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

  def vaccination_records
    scope =
      programme
        .vaccination_records
        .joins(:organisation)
        .where(organisations: { id: organisation.id })
        .merge(VaccinationRecord.administered)
        .includes(
          :batch,
          :location,
          :performed_by_user,
          :programme,
          :vaccine,
          patient: %i[gp_practice school]
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

  def row(vaccination_record:)
    patient = vaccination_record.patient

    [
      organisation.ods_code, # Practice code
      patient.nhs_number, # NHS number
      patient.family_name, # Surname
      "", # Middle name (not stored)
      patient.given_name, # Forename
      gender_code(patient.gender_code), # Gender
      patient.date_of_birth.to_fs(:uk_short),
      patient.address_line_2, # House name
      patient.address_line_1, # House number and road
      patient.address_town, # Town
      patient.address_postcode, # Postcode
      vaccination(vaccination_record), # Vaccination
      "", # Part
      vaccination_record.performed_at.to_date.to_fs(:uk_short), # Admin date
      vaccination_record.batch&.name, # Batch number
      vaccination_record.batch&.expiry&.to_fs(:uk_short), # Expiry date
      vaccination_record.dose_volume_ml, # Dose
      reason(vaccination_record), # Reason (not specified)
      vaccination_record.delivery_site, # Site
      vaccination_record.delivery_method, # Method
      vaccination_record.notes # Notes
    ]
  end

  def gender_code(code)
    { male: "M", female: "F", not_specified: "U", not_known: "U" }[code.to_sym]
  end

  def vaccination(vaccination_record)
    "#{vaccination_record.vaccine.brand} dose #{vaccination_record.dose_sequence}"
  end

  def reason(vaccination_record)
    case vaccination_record.dose_sequence
    when 1, nil
      "Routine"
    else
      "At Risk"
    end
  end
end
