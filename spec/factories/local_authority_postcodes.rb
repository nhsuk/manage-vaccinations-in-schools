# frozen_string_literal: true

# == Schema Information
#
# Table name: local_authority_postcodes
#
#  gss_code   :string           not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_local_authority_postcodes_on_gss_code  (gss_code)
#  index_local_authority_postcodes_on_value     (value) UNIQUE
#
FactoryBot.define do
  factory :local_authority_postcode, class: "LocalAuthority::Postcode" do
  end
end
