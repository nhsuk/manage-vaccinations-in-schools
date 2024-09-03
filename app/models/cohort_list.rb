# frozen_string_literal: true

require "csv"

class CohortList
  include ActiveModel::Model
  include CSVImportable

  attr_accessor :csv_data, :csv_filename

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

  def required_headers
    %w[
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
    ]
  end

  def parse_row(row_data)
    CohortListRow.new(
      row_data
        .to_h
        .slice(*required_headers) # Remove extra columns
        .transform_keys { _1.downcase.to_sym }
    )
  end
end
