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
#  name                      :text             not null
#  ods_code                  :string
#  status                    :integer          default("unknown"), not null
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  year_groups               :integer          default([]), not null, is an Array
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  team_id                   :bigint
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_team_id   (team_id)
#  index_locations_on_urn       (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  factory :location do
    transient { organisation { nil } }

    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    url { Faker::Internet.url }

    team do
      if organisation
        organisation.teams.first || association(:team, organisation:)
      end
    end

    traits_for_enum :status

    factory :community_clinic do
      type { :community_clinic }
      name { "#{Faker::University.name} Clinic" }

      sequence(:ods_code, 100) { "CL#{_1}" }

      organisation
    end

    factory :generic_clinic do
      type { :generic_clinic }
      name { "Community clinics" }

      ods_code { team&.organisation&.ods_code }
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

      trait :primary do
        year_groups { (0..6).to_a }
      end

      trait :secondary do
        name { Faker::Educator.secondary_school }
        year_groups { (7..11).to_a }
      end
    end
  end
end
