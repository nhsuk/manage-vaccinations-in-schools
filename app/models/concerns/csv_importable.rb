# frozen_string_literal: true

require "csv"

module CSVImportable
  extend ActiveSupport::Concern

  included do
    attr_accessor :csv_is_malformed, :data, :rows

    validates :csv,
              absence: {
                if: -> { try(:csv_removed?) || false }
              },
              presence: {
                unless: -> { try(:csv_removed?) || false }
              }
    validates :csv_filename, presence: true

    validate :csv_is_valid
    validate :csv_has_records
    validate :headers_are_valid
    validate :rows_are_valid
  end

  def csv=(file)
    self.csv_data = file&.read
    self.csv_filename = file&.original_filename
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

    self.rows = data.map { |row_data| parse_row(row_data) }
  end

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

    missing_headers = required_headers - data.headers
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
