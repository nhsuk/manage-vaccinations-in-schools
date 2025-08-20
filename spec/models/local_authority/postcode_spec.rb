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
describe LocalAuthority::Postcode, type: :model do
  it { should normalize(:value).from(" Sw111AA ").to("SW11 1AA") }
  it { should normalize(:value).from(" Sw11.   1aA ").to("SW11 1AA") }
  it { should normalize(:value).from(" ,dH1.  3lh. ").to("DH1 3LH") }
end
