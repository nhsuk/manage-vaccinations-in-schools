# frozen_string_literal: true

class Reports::SystmOneExporter
  GENDER_CODE_MAPPINGS = {
    male: "M",
    female: "F",
    not_specified: "U",
    not_known: "U"
  }.with_indifferent_access.freeze

  VACCINE_DOSE_MAPPINGS = {
    "Gardasil 9" => {
      "1" => "Y19a4",
      "2" => "Y19a5",
      "3" => "Y19a6"
    }
  }.freeze

  DELIVERY_SITE_MAPPINGS = {
    left_arm_upper_position: "Left deltoid",
    left_arm_lower_position: "Left anterior forearm",
    left_thigh: "Left lateral thigh",
    right_arm_upper_position: "Right deltoid",
    right_arm_lower_position: "Right anterior forearm",
    right_thigh: "Right lateral thigh",
    nose: "Nasal"
  }.with_indifferent_access.freeze

  DELIVERY_METHOD_MAPPINGS = {
    intramuscular: "Intramuscular",
    subcutaneous: "Subcutaneous",
    nasal_spray: "Nasal"
  }.with_indifferent_access.freeze

  def initialize(team:, programme:, academic_year:, start_date:, end_date:)
    @team = team
    @programme = programme
    @academic_year = academic_year
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

  attr_reader :team, :programme, :academic_year, :start_date, :end_date

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
      team
        .vaccination_records
        .administered
        .where(programme:)
        .for_academic_year(academic_year)
        .includes(:batch, :location, :vaccine, :patient, :performed_by_user)

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
      practice_code(vaccination_record), # Practice code
      patient.nhs_number, # NHS number
      patient.family_name, # Surname
      "", # Middle name (not stored)
      patient.given_name, # Forename
      gender_code(patient.gender_code), # Gender
      patient.date_of_birth.to_fs(:uk_short),
      patient.restricted? ? "" : patient.address_line_2, # House name
      patient.restricted? ? "" : patient.address_line_1, # House number and road
      patient.restricted? ? "" : patient.address_town, # Town
      patient.restricted? ? "" : patient.address_postcode, # Postcode
      vaccination(vaccination_record), # Vaccination
      "", # Part
      vaccination_record.performed_at.to_date.to_fs(:uk_short), # Admin date
      vaccination_record.batch&.name, # Batch number
      vaccination_record.batch&.expiry&.to_fs(:uk_short), # Expiry date
      vaccination_record.dose_volume_ml, # Dose
      reason(vaccination_record), # Reason (not specified)
      site(vaccination_record), # Site
      method(vaccination_record), # Method
      notes(vaccination_record) # Notes
    ]
  end

  # TODO: Needs support for community and generic clinics.
  def practice_code(vaccination_record)
    location = vaccination_record.location

    location.school? ? location.urn : location.ods_code
  end

  def gender_code(code)
    GENDER_CODE_MAPPINGS[code]
  end

  # TODO: These mappings are valid for Hertforshire, but may not be correct for
  #       other SAIS teams. We'll need to check these are correct with new SAIS
  #       teams.
  def vaccination(vaccination_record)
    return if vaccination_record.not_administered?

    VACCINE_DOSE_MAPPINGS.dig(
      vaccination_record.vaccine.brand,
      vaccination_record.dose_sequence.to_s
    ) ||
      "#{vaccination_record.vaccine.brand} " \
        "Part #{vaccination_record.dose_sequence}"
  end

  def reason(vaccination_record)
    case vaccination_record.dose_sequence
    when 1, nil
      "Routine"
    else
      "At Risk"
    end
  end

  # TODO: These mappings are valid for Hertforshire, but may not be correct for
  #       other SAIS teams. We'll need to check these are correct with new SAIS
  #       teams.
  def site(vaccination_record)
    return if vaccination_record.not_administered?

    DELIVERY_SITE_MAPPINGS.fetch(vaccination_record.delivery_site)
  end

  def notes(vaccination_record)
    notes = vaccination_record.notes.to_s
    if vaccination_record.performed_by
      notes += (notes.empty? ? "" : "\n ")
      notes +=
        "Administered by: #{vaccination_record.performed_by.given_name}" \
          " #{vaccination_record.performed_by.family_name}"
    end
    notes
  end

  def method(vaccination_record)
    return if vaccination_record.not_administered?

    DELIVERY_METHOD_MAPPINGS.fetch(vaccination_record.delivery_method)
  end
end
