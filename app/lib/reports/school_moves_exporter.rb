# frozen_string_literal: true

class Reports::SchoolMovesExporter
  include Reports::ExportFormatters

  HEADERS = %i[
    NHS_REF
    SURNAME
    FORENAME
    GENDER
    DOB
    ADDRESS1
    ADDRESS2
    ADDRESS3
    TOWN
    POSTCODE
    COUNTY
    ETHNIC_OR
    ETHNIC_DESCRIPTION
    NATIONAL_URN_NO
    BASE_NAME
    STARTDATE
    STUD_ID
    DES_NUMBER
  ].freeze

  def initialize(organisation:, start_date:, end_date:)
    @organisation = organisation
    @start_date = start_date
    @end_date = end_date
  end

  def row_count = school_move_log_entries.count

  def csv_data
    CSV.generate(headers: HEADERS, write_headers: true) do |csv|
      school_move_log_entries
        .includes(:patient, :school)
        .order(:created_at)
        .find_each { |log_entry| csv << row(log_entry) }
    end
  end

  private

  attr_reader :organisation, :start_date, :end_date

  def school_move_log_entries
    @school_move_log_entries ||=
      begin
        historical_patients =
          Patient
            .where.not(id: organisation.patients.select(:id))
            .where(
              SchoolMoveLogEntry
                .where("patient_id = patients.id")
                .where(school: organisation.schools)
                .arel
                .exists
            )

        scope =
          SchoolMoveLogEntry
            .where(school: organisation.schools)
            .or(
              SchoolMoveLogEntry.where(
                patient: organisation.patients,
                school: nil
              )
            )
            .or(
              SchoolMoveLogEntry
                .where.not(patient: organisation.patients)
                .where(patient: historical_patients)
            )

        if start_date.present?
          scope =
            scope.where(
              "school_move_log_entries.created_at >= ?",
              start_date.beginning_of_day
            )
        end

        if end_date.present?
          scope =
            scope.where(
              "school_move_log_entries.created_at <= ?",
              end_date.end_of_day
            )
        end

        scope
      end
  end

  def row(log_entry)
    patient = log_entry.patient
    location = log_entry.school

    [
      patient.nhs_number,
      patient.family_name,
      patient.given_name,
      patient.gender_code.humanize,
      patient.date_of_birth.iso8601,
      patient.address_line_1,
      patient.address_line_2,
      nil,
      patient.address_town,
      patient.address_postcode,
      nil,
      nil,
      nil,
      school_urn(location:, patient:),
      location&.name,
      log_entry.created_at.iso8601,
      nil,
      nil
    ]
  end
end
