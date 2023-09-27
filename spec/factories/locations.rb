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
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :location do
    name { Faker::Educator.primary_school }
    address { Faker::Address.street_address }
    locality { "" }
    town { Faker::Address.city }
    county { Faker::Address.county }
    postcode { Faker::Address.postcode }
    # minimum_age { 1 }
    # maximum_age { 1 }
    url { Faker::Internet.url }
    # phase { "Primary" }
    # type { "Local authority maintained schools" }
    # detailed_type { "Voluntary aided school" }
  end
end
