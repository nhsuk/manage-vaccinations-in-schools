# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                      :bigint           not null, primary key
#  reception_starting_year :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  team_id                 :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id                              (team_id)
#  index_cohorts_on_team_id_and_reception_starting_year  (team_id,reception_starting_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Cohort < ApplicationRecord
  belongs_to :team

  has_many :patients
  has_many :recorded_patients, -> { recorded }, class_name: "Patient"

  validates :reception_starting_year,
            comparison: {
              greater_than_or_equal_to: 1990
            }

  scope :for_year_groups,
        ->(year_groups) do
          academic_year = Time.zone.today.academic_year

          reception_starting_years =
            year_groups.map { |year_group| academic_year - year_group }

          where(reception_starting_year: reception_starting_years)
        end

  def self.find_or_create_by_date_of_birth!(date_of_birth, team:)
    # Children normally start school the September after their 4th birthday.
    # https://www.gov.uk/schools-admissions/school-starting-age

    reception_starting_year = date_of_birth.academic_year + 5
    Cohort.find_or_create_by!(team:, reception_starting_year:)
  end

  def year_group
    Time.zone.today.academic_year - reception_starting_year
  end
end
