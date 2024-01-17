require "csv"

class CohortList
  include ActiveModel::Model

  EXPECTED_HEADERS = %w[
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

  attr_accessor :csv, :csv_is_malformed, :data, :rows

  validates :csv, presence: true
  validate :csv_is_valid

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv.read, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  ensure
    csv.close if csv.respond_to?(:close)
  end

  def parse_rows!
    unless data.headers == EXPECTED_HEADERS
      html_missing_headers =
        (EXPECTED_HEADERS - data.headers).map { "<code>#{_1}</code>" }
      errors.add(
        :csv,
        "The file is missing the following headers: #{html_missing_headers.join(", ")}"
      )
      return
    end

    self.rows = data.map.with_index do |raw_row, index|
      row_hash = raw_row.to_h.transform_keys { _1.downcase.to_sym }
      row = CohortListRow.new(row_hash)
      unless row.valid?
        errors.add("row_#{index}".to_sym, row.errors.full_messages)
      end
      row
    end
  end

  private

  def csv_is_valid
    errors.add(:csv, :invalid) if csv_is_malformed
  end
end
