# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                  :bigint           not null, primary key
#  birth_academic_year :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#
# Indexes
#
#  index_cohorts_on_organisation_id                          (organisation_id)
#  index_cohorts_on_organisation_id_and_birth_academic_year  (organisation_id,birth_academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
class Cohort < ApplicationRecord
  include YearGroupConcern

  belongs_to :organisation

  has_many :patients

  scope :for_year_groups,
        ->(year_groups, academic_year: nil) do
          birth_academic_years =
            year_groups.map do |year_group|
              year_group.to_birth_academic_year(academic_year:)
            end

          where(birth_academic_year: birth_academic_years)
        end

  validates :birth_academic_year, comparison: { greater_than_or_equal_to: 1990 }
end
