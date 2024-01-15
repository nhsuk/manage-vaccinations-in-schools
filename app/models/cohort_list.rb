require "csv"

class CohortList
  include ActiveModel::Model

  attr_accessor :csv, :data

  validates :csv, presence: true
  validate :csv_is_valid

  def generate_cohort!
    # Parse the CSV and create a Patient for each row
  end

  private

  def csv_is_valid
    return if csv.blank?

    self.data = CSV.parse(csv.read, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    errors.add(:csv, :invalid)
  ensure
    csv.close if csv.respond_to?(:close)
  end
end
