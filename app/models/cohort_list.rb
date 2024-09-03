# frozen_string_literal: true

require "csv"

class CohortList
  include ActiveModel::Model

  attr_accessor :csv_data, :csv_is_malformed, :data, :rows

  REQUIRED_HEADERS = %w[
    SCHOOL_URN
    SCHOOL_NAME
    PARENT_NAME
    PARENT_RELATIONSHIP
    PARENT_EMAIL
    PARENT_PHONE
    CHILD_FIRST_NAME
    CHILD_LAST_NAME
    CHILD_COMMON_NAME
    CHILD_DATE_OF_BIRTH
    CHILD_ADDRESS_LINE_1
    CHILD_ADDRESS_LINE_2
    CHILD_ADDRESS_TOWN
    CHILD_ADDRESS_POSTCODE
    CHILD_NHS_NUMBER
  ].freeze

  validates :csv, presence: true

  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid
  validate :rows_are_valid

  def csv=(file)
    self.csv_data = file&.read
  end

  # Needed so that validations match the form field name.
  def csv
    csv_data
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv_data, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  end

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows =
      data.map do |raw_row|
        CohortListRow.new(
          raw_row
            .to_h
            .slice(*REQUIRED_HEADERS) # Remove extra columns
            .transform_keys { _1.downcase.to_sym }
        )
      end
  end

  def process!
    parse_rows! if rows.nil?
    return if invalid?

    rows.each do |row|
      location = Location.find_by(urn: row.school_urn)
      patient =
        location.patients.new(
          row.to_patient.merge(parent: Parent.new(row.to_parent))
        )
      patient.save!
    end
  end

  private

  def csv_is_valid
    return unless csv_is_malformed

    errors.add(:csv, :invalid)
  end

  def csv_has_records
    return unless data

    errors.add(:csv, :empty) if data.empty?
  end

  def headers_are_valid
    return unless data

    missing_headers = REQUIRED_HEADERS - data.headers
    errors.add(:csv, :missing_headers, missing_headers:) if missing_headers.any?
  end

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      if row.invalid?
        errors.add("row_#{index + 1}".to_sym, row.errors.full_messages)
      end
    end
  end
end
