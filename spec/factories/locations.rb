# == Schema Information
#
# Table name: locations
#
#  id                             :bigint           not null, primary key
#  address                        :text
#  county                         :text
#  locality                       :text
#  name                           :text
#  permission_to_observe_required :boolean
#  postcode                       :text
#  town                           :text
#  url                            :text
#  urn                            :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  team_id                        :integer          not null
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
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
    team { Team.first || association(:team) }
    urn { rand(100_000..999_999).to_s }
    permission_to_observe_required { true }
  end
end
