# frozen_string_literal: true

# == Schema Information
#
# Table name: team_locations
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :bigint           not null
#  subteam_id    :bigint
#  team_id       :bigint           not null
#
# Indexes
#
#  idx_on_team_id_academic_year_location_id_1717f14a0c  (team_id,academic_year,location_id) UNIQUE
#  index_team_locations_on_location_id                  (location_id)
#  index_team_locations_on_subteam_id                   (subteam_id)
#  index_team_locations_on_team_id                      (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (subteam_id => subteams.id)
#  fk_rails_...  (team_id => teams.id)
#

FactoryBot.define do
  factory :team_location do
    team
    location
    academic_year { AcademicYear.current }
  end
end
