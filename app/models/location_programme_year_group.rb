# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  year_group    :integer          not null
#  location_id   :bigint           not null
#  programme_id  :bigint           not null
#
# Indexes
#
#  idx_on_location_id_academic_year_programme_id_year__6ad5e2b67d  (location_id,academic_year,programme_id,year_group) UNIQUE
#  index_location_programme_year_groups_on_programme_id            (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
class LocationProgrammeYearGroup < ApplicationRecord
  audited associated_with: :location

  belongs_to :location
  belongs_to :programme

  scope :pluck_year_groups,
        -> { distinct.order(:year_group).pluck(:year_group) }

  scope :pluck_birth_academic_years,
        -> do
          distinct
            .order(:academic_year, :year_group)
            .pluck(:academic_year, :year_group)
            .map { _2.to_birth_academic_year(academic_year: _1) }
        end

  validates :year_group, inclusion: { in: :valid_year_groups }

  def birth_academic_year
    year_group.to_birth_academic_year(academic_year:)
  end

  private

  def valid_year_groups
    location&.location_year_groups&.where(academic_year:)&.pluck_values || []
  end
end
