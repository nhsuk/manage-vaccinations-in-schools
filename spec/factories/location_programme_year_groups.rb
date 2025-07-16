# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id           :bigint           not null, primary key
#  year_group   :integer          not null
#  location_id  :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  idx_on_location_id_programme_id_year_group_4bee220488  (location_id,programme_id,year_group) UNIQUE
#  index_location_programme_year_groups_on_location_id    (location_id)
#  index_location_programme_year_groups_on_programme_id   (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :location_programme_year_group,
          class: "Location::ProgrammeYearGroup" do
    location
    programme
    year_group { (0..13).to_a.sample }
  end
end
