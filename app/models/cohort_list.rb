class CohortList
  include ActiveModel::Model

  attr_accessor :csv

  validates :csv, presence: true

  def generate_cohort!
    # Parse the CSV and create a Patient for each row
  end
end
