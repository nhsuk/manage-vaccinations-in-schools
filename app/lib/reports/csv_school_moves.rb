# frozen_string_literal: true

class Reports::CSVSchoolMoves
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
      school_move_log_entries.each do |log_entry|
        csv << row(log_entry.school, log_entry.patient)
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :school_move_log_entries

  def row(school, patient)
    [
      patient.nhs_number,
      patient.family_name,
      patient.given_name,
      patient.gender_code.humanize,
      patient.date_of_birth.to_fs(:govuk),
      patient.address_line_1,
      patient.address_line_2,
      nil,
      patient.address_town,
      patient.address_postcode,
      nil,
      nil,
      nil,
      school_urn(school, patient),
      school&.name,
      school&.created_at&.to_fs(:govuk),
      nil,
      nil
    ]
  end

  def school_urn(school, patient)
    if school
      school.urn
    elsif patient.home_educated?
      "999999"
    else
      patient.school&.urn || "888888"
    end
  end
end
