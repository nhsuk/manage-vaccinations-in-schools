# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id                     :bigint           not null, primary key
#  programme_type         :enum             not null
#  location_year_group_id :bigint           not null
#  programme_id           :bigint           not null
#
# Indexes
#
#  idx_on_location_year_group_id_programme_id_405f51181e           (location_year_group_id,programme_id) UNIQUE
#  idx_on_location_year_group_id_programme_type_904fa3b284         (location_year_group_id,programme_type) UNIQUE
#  index_location_programme_year_groups_on_location_year_group_id  (location_year_group_id)
#  index_location_programme_year_groups_on_programme_id            (programme_id)
#  index_location_programme_year_groups_on_programme_type          (programme_type)
#
# Foreign Keys
#
#  fk_rails_...  (location_year_group_id => location_year_groups.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :location_programme_year_group,
          class: "Location::ProgrammeYearGroup" do
    transient do
      location { association :location }
      academic_year { AcademicYear.pending }
      year_group { programme.default_year_groups.sample }
    end

    location_year_group do
      location.location_year_groups.find_or_initialize_by(
        academic_year:,
        value: year_group
      )
    end

    programme { CachedProgramme.sample }
  end
end
