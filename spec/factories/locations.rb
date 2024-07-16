# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  address    :text
#  county     :text
#  locality   :text
#  name       :text
#  postcode   :text
#  town       :text
#  url        :text
#  urn        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_locations_on_urn  (urn) UNIQUE
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
    urn { rand(100_000..999_999).to_s }
  end
end
