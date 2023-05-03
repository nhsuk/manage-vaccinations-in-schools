# == Schema Information
#
# Table name: schools
#
#  id            :bigint           not null, primary key
#  address       :text
#  county        :text
#  detailed_type :text
#  locality      :text
#  maximum_age   :decimal(, )
#  minimum_age   :decimal(, )
#  name          :text
#  phase         :integer
#  postcode      :text
#  town          :text
#  type          :text
#  url           :text
#  urn           :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_schools_on_urn  (urn) UNIQUE
#
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
