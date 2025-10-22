# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id                     :bigint           not null, primary key
#  location_year_group_id :bigint           not null
#  programme_id           :bigint           not null
#
# Indexes
#
#  idx_on_location_year_group_id_programme_id_405f51181e           (location_year_group_id,programme_id) UNIQUE
#  index_location_programme_year_groups_on_location_year_group_id  (location_year_group_id)
#  index_location_programme_year_groups_on_programme_id            (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_year_group_id => location_year_groups.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
class Location::ProgrammeYearGroup < ApplicationRecord
  audited associated_with: :location_year_group

  belongs_to :location_year_group, class_name: "Location::YearGroup"
  belongs_to :programme

  has_one :location, through: :location_year_group

  scope :pluck_year_groups,
        -> do
          joins(:location_year_group)
            .distinct
            .order(:"location_year_group.value")
            .pluck(:"location_year_group.value")
        end

  scope :pluck_birth_academic_years,
        -> do
          joins(:location_year_group)
            .distinct
            .order(
              :"location_year_group.academic_year",
              :"location_year_group.value"
            )
            .pluck(
              :"location_year_group.academic_year",
              :"location_year_group.value"
            )
            .map { _2.to_birth_academic_year(academic_year: _1) }
        end

  def year_group = location_year_group.value

  delegate :birth_academic_year, to: :location_year_group
end
