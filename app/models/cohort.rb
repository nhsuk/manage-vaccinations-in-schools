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

  has_and_belongs_to_many :patients

  def year_group
    today = Time.zone.today

    academic_year =
      if today.month >= 9
        today.year
      else
        today.year - 1
      end

    academic_year - reception_starting_year
  end
end
