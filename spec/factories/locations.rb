# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  address    :text
#  county     :text
#  locality   :text
#  name       :text             not null
#  ods_code   :string
#  postcode   :text
#  town       :text
#  type       :integer          not null
#  url        :text
#  urn        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_urn       (urn) UNIQUE
#
FactoryBot.define do
  factory :location do
    name { Faker::Educator.primary_school }
    address { Faker::Address.street_address }
    locality { "" }
    town { Faker::Address.city }
    county { Faker::Address.county }
    postcode { Faker::Address.postcode }
    url { Faker::Internet.url }

    trait :generic_clinic do
      type { :generic_clinic }
      sequence(:ods_code, 10_000, &:to_s)
      urn { nil }
    end

    trait :school do
      type { :school }
      ods_code { nil }
      sequence(:urn, 100_000, &:to_s)
    end
  end
end
