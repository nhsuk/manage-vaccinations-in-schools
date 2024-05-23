require "csv"

class CohortList
  include ActiveModel::Model

  EXPECTED_HEADERS = %w[
    SCHOOL_ID
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

  attr_accessor :csv, :csv_is_malformed, :data, :missing_headers, :rows, :team

  validates :csv, presence: true
  validate :csv_is_valid
  validate :headers_are_valid
  validate :rows_are_valid

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv.read, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  ensure
    csv.close if csv.respond_to?(:close)
  end

  def parse_rows!
    if (EXPECTED_HEADERS - data.headers) != []
      self.missing_headers = EXPECTED_HEADERS - data.headers
      return
    end

    self.rows =
      data.map do |raw_row|
        CohortListRow.new(
          raw_row
            .to_h
            .slice(*EXPECTED_HEADERS) # Remove extra columns
            .transform_keys { _1.downcase.to_sym }
            .merge(team:)
        )
      end
  end

  def generate_patients!
    return if invalid?

    rows.each do |row|
      location = Location.find(row.school_id)
      patient = location.patients.new(row.to_patient)
      patient.save!
    end
  end

  private

  def csv_is_valid
    return unless csv_is_malformed

    errors.add(:csv, :invalid)
  end

  def headers_are_valid
    return unless missing_headers

    html_missing_headers = missing_headers.map { "<code>#{_1}</code>" }
    errors.add(
      :csv,
      "The file is missing the following headers: #{html_missing_headers.join(", ")}"
    )
  end

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      unless row.valid?
        # Row 0 is the header row, but humans would call it Row 1. That's also
        # what it would be shown as in Excel. The first row of data is Row 2.
        errors.add("row_#{index + 2}".to_sym, row.errors.full_messages)
      end
    end
  end
end
