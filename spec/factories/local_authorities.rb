# == Schema Information
#
# Table name: local_authorities
#
#  end_date                  :date
#  gias_local_authority_code :integer
#  gov_uk_slug               :string
#  gss_code                  :string
#  local_authority_code      :string           not null, primary key
#  nation                    :string
#  official_name             :string
#  region                    :string
#  short_name                :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_local_authorities_on_created_at             (created_at)
#  index_local_authorities_on_gss_code               (gss_code) UNIQUE
#  index_local_authorities_on_local_authority_code   (local_authority_code) UNIQUE
#  index_local_authorities_on_nation_and_short_name  (nation,short_name)
#  index_local_authorities_on_short_name             (short_name)
#
FactoryBot.define do
  factory :local_authority do
    local_authority_code { Array('A'..'Z').sample(3).join }
    gias_local_authority_code { Array(0..9).sample(3).join }
    official_name { [Faker::Address.city, "Council"].join(" ") }
    short_name { [Faker::Address.city] }
    region do
      ["Yorkshire and The Humber", "West Midlands", "East Midlands", "Northern Ireland", "South East", "Wales", nil, 
      "East of England", "Scotland", "North East", "North West", "South West", "London"].sample
    end
    nation { "England" }
    gov_uk_slug { ["/", Faker::Address.city.downcase.gsub(/[^A-Z]+/i,'-' ) ].join}  
  end
end
