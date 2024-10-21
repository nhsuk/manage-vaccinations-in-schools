# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address_line_1   :text
#  address_line_2   :text
#  address_postcode :text
#  address_town     :text
#  name             :text             not null
#  ods_code         :string
#  type             :integer          not null
#  url              :text
#  urn              :string
#  year_groups      :integer          default([]), not null, is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  team_id          :bigint
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
    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    url { Faker::Internet.url }

    trait :clinic do
      type { :clinic }
      name { "#{Faker::University.name} Clinic" }
      sequence(:ods_code, 10_000, &:to_s)
      urn { nil }
    end

    trait :school do
      type { :school }
      name { Faker::Educator.primary_school }
      sequence(:urn, 100_000, &:to_s)
      ods_code { nil }
    end

    trait :primary do
      school
      name { Faker::Educator.primary_school }
      year_groups { (0..6).to_a }
    end

    trait :secondary do
      school
      name { Faker::Educator.secondary_school }
      year_groups { (7..11).to_a }
    end
  end
end
