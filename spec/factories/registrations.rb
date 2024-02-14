# == Schema Information
#
# Table name: registrations
#
#  id                          :bigint           not null, primary key
#  address_line_1              :string
#  address_line_2              :string
#  address_postcode            :string
#  address_town                :string
#  common_name                 :string
#  consent_response_confirmed  :boolean
#  data_processing_agreed      :boolean
#  date_of_birth               :date
#  first_name                  :string
#  last_name                   :string
#  nhs_number                  :string
#  parent_email                :string
#  parent_name                 :string
#  parent_phone                :string
#  parent_relationship         :integer
#  parent_relationship_other   :string
#  terms_and_conditions_agreed :boolean
#  use_common_name             :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  location_id                 :bigint           not null
#
# Indexes
#
#  index_registrations_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#
FactoryBot.define do
  factory :registration do
    transient { random { Random.new } }
    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_postcode { Faker::Address.postcode }
    address_town { Faker::Address.city }
    common_name { Faker::Name.first_name }
    date_of_birth { Faker::Date.birthday(min_age: 3, max_age: 9) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    nhs_number { Faker::NationalHealthService.british_number.gsub(/\s+/, "") }
    parent_email { Faker::Internet.email }
    parent_name { Faker::Name.name }
    parent_phone { "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}" }
    parent_relationship do
      Registration.parent_relationships.keys.sample(random:)
    end
    parent_relationship_other do
      %w[Aunt Uncle Grandfather Grandmother].sample(random:)
    end
    use_common_name { Faker::Boolean.boolean }
    location
    terms_and_conditions_agreed { true }
    data_processing_agreed { true }
    consent_response_confirmed { true }
  end
end
