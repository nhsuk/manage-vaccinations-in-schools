# frozen_string_literal: true

# == Schema Information
#
# Table name: local_authorities
#
#  end_date      :date
#  gias_code     :integer
#  gov_uk_slug   :string
#  gss_code      :string
#  mhclg_code    :string           not null, primary key
#  nation        :string           not null
#  official_name :string           not null
#  region        :string
#  short_name    :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_local_authorities_on_created_at             (created_at)
#  index_local_authorities_on_gias_code              (gias_code) UNIQUE
#  index_local_authorities_on_gss_code               (gss_code) UNIQUE
#  index_local_authorities_on_mhclg_code             (mhclg_code) UNIQUE
#  index_local_authorities_on_nation_and_short_name  (nation,short_name)
#  index_local_authorities_on_short_name             (short_name)
#
FactoryBot.define do
  factory :local_authority do
    mhclg_code { Array("A".."Z").sample(3).join }
    gias_code { Array(0..9).sample(3).join }
    official_name { [Faker::Address.city, "Council"].join(" ") }
    short_name { [Faker::Address.city] }
    region { LocalAuthority.regions.keys.sample }
    nation { LocalAuthority.nations.keys.sample }
    gov_uk_slug do
      ["/", Faker::Address.city.downcase.gsub(/[^A-Z]+/i, "-")].join
    end
  end
end
