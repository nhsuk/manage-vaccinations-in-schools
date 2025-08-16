# frozen_string_literal: true

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
class LocalAuthority < ApplicationRecord
  self.primary_key = :local_authority_code

  def self.from_my_society_import_row(data)
    new(
      local_authority_code: data["local-authority-code"],
      gss_code: data["gss-code"],
      gov_uk_slug: data["gov-uk-slug"],
      official_name: data["official-name"],
      short_name: data["nice-name"],
      nation: data["nation"],
      region: data["region"],
      end_date: data["end-date"]
    )
  end
end
