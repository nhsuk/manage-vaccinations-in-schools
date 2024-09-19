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
FactoryBot.define do
  factory :cohort do
    team
    birth_academic_year { Time.zone.today.year - 10 }
  end
end
