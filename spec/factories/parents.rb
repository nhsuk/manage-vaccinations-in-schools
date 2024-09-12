# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                           :bigint           not null, primary key
#  contact_method_other_details :text
#  contact_method_type          :string
#  email                        :string
#  name                         :string
#  phone                        :string
#  recorded_at                  :datetime
#  relationship                 :integer
#  relationship_other           :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
FactoryBot.define do
  factory :parent do
    transient do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
    end

    name { "#{first_name} #{last_name}" }
    email { Faker::Internet.email }
    phone { "07700 900#{rand(0..999).to_s.rjust(3, "0")}" }

    trait :contact_method_any do
      contact_method_type { "any" }
    end

    trait :contact_method_text do
      contact_method_type { "text" }
    end

    trait :contact_method_voice do
      contact_method_type { "voice" }
    end

    trait :contact_method_other do
      contact_method_type { "other" }
      contact_method_other_details { "Other details." }
    end

    trait :recorded do
      recorded_at { Time.zone.now }
    end

    trait :draft do
      recorded_at { nil }
    end
  end
end
