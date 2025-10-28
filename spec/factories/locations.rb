# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id                        :bigint           not null, primary key
#  address_line_1            :text
#  address_line_2            :text
#  address_postcode          :text
#  address_town              :text
#  gias_establishment_number :integer
#  gias_local_authority_code :integer
#  gias_year_groups          :integer          default([]), not null, is an Array
#  name                      :text             not null
#  ods_code                  :string
#  site                      :string
#  status                    :integer          default("unknown"), not null
#  systm_one_code            :string
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  subteam_id                :bigint
#
# Indexes
#
#  index_locations_on_ods_code        (ods_code) UNIQUE
#  index_locations_on_subteam_id      (subteam_id)
#  index_locations_on_systm_one_code  (systm_one_code) UNIQUE
#  index_locations_on_urn             (urn) UNIQUE WHERE (site IS NULL)
#  index_locations_on_urn_and_site    (urn,site) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subteam_id => subteams.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  factory :location do
    transient do
      team { nil }
      programmes { subteam&.team&.programmes || [] }
      academic_year { AcademicYear.pending }
    end

    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    url { Faker::Internet.url }

    subteam { team.subteams.first || association(:subteam, team:) if team }

    traits_for_enum :status

    factory :community_clinic do
      type { :community_clinic }
      name { "#{Faker::University.name} Clinic" }

      sequence(:ods_code, 100) { "CL#{_1}" }
    end

    factory :generic_clinic do
      type { :generic_clinic }
      name { "Community clinic" }

      after(:create) do |location, evaluator|
        year_groups = Location::YearGroup::CLINIC_VALUE_RANGE.to_a
        academic_year = evaluator.academic_year

        location.import_year_groups!(
          year_groups,
          academic_year:,
          source: "generic_clinic_factory"
        )
        location.import_default_programme_year_groups!(
          evaluator.programmes,
          academic_year:
        )
      end
    end

    factory :gp_practice do
      type { :gp_practice }
      name { "#{Faker::University.name} Practice" }

      sequence(:ods_code, 100) { "GP#{_1}" }
    end

    factory :school do
      type { :school }
      name { Faker::Educator.primary_school }

      sequence(:gias_establishment_number, 1)
      sequence(:gias_local_authority_code, 1)
      sequence(:urn, 100_000, &:to_s)

      gias_year_groups { (0..11).to_a }

      trait :primary do
        gias_year_groups { (0..6).to_a }
      end

      trait :secondary do
        name { Faker::Educator.secondary_school }
        gias_year_groups { (7..11).to_a }
      end

      after(:create) do |location, evaluator|
        academic_year = evaluator.academic_year
        location.import_year_groups_from_gias!(academic_year:)
        location.import_default_programme_year_groups!(
          evaluator.programmes,
          academic_year:
        )
      end
    end
  end
end
