# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  year_group    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id                                   (team_id)
#  index_cohorts_on_team_id_and_academic_year_and_year_group  (team_id,academic_year,year_group) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :cohort do
    team
    academic_year { Time.zone.today.year }
    year_group { 7 }
  end
end
