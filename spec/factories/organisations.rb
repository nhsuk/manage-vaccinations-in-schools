# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id         :bigint           not null, primary key
#  ods_code   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
FactoryBot.define do
  sequence(:ods_code) { |n| "U#{n}" }

  factory :organisation do
    ods_code { generate(:ods_code) }
  end
end
