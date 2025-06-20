# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_checks
#
#  id                              :bigint           not null, primary key
#  confirmed_by_other_name         :string           default(""), not null
#  confirmed_by_other_relationship :string           default(""), not null
#  confirmed_by_patient            :boolean          not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  vaccination_record_id           :bigint           not null
#
# Indexes
#
#  index_identity_checks_on_vaccination_record_id  (vaccination_record_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccination_record_id => vaccination_records.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :identity_check do
    vaccination_record

    trait :confirmed_by_patient do
      confirmed_by_patient { true }
      confirmed_by_other_name { "" }
      confirmed_by_other_relationship { "" }
    end

    trait :confirmed_by_other do
      confirmed_by_patient { false }
      confirmed_by_other_name { Faker::Name.name }
      confirmed_by_other_relationship { Faker::Relationship.familial }
    end
  end
end
