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

  def initialize(school_move_log_entries)
    @school_move_log_entries = school_move_log_entries
  end

  def call
    CSV.generate(headers: HEADERS, write_headers: true) do |csv|
      school_move_log_entries
        .includes(:patient, :school)
        .find_each { |log_entry| csv << row(log_entry) }
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :school_move_log_entries

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
