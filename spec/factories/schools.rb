FactoryBot.define do
  factory :school do
    name { Faker::Educator.primary_school }
    address { Faker::Address.street_address }
    locality { "" }
    town { Faker::Address.city }
    county { Faker::Address.county }
    postcode { Faker::Address.postcode }
    minimum_age { 1 }
    maximum_age { 1 }
    url { Faker::Internet.url }
    phase { "Primary" }
    type { "Local authority maintained schools" }
    detailed_type { "Voluntary aided school" }
  end
end
