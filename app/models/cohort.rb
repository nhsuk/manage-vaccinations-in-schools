# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                  :bigint           not null, primary key
#  birth_academic_year :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  team_id             :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id                          (team_id)
#  index_cohorts_on_team_id_and_birth_academic_year  (team_id,birth_academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Cohort < ApplicationRecord
  belongs_to :team

  has_many :patients

  validates :birth_academic_year, comparison: { greater_than_or_equal_to: 1990 }

  scope :for_year_groups,
        ->(year_groups) do
          academic_year = Time.zone.today.academic_year

          birth_academic_years =
            year_groups.map { |year_group| academic_year - year_group - 5 }

          where(birth_academic_year: birth_academic_years)
        end

  scope :for_programme,
        ->(programme) do
          where(team_id: programme.team_id).for_year_groups(
            programme.year_groups
          )
        end

  def year_group
    Date.new(birth_academic_year, 9, 1).year_group
  end
end
