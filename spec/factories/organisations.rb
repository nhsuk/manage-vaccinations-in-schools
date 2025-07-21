# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id                            :bigint           not null, primary key
#  careplus_venue_code           :string           not null
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  phone_instructions            :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_organisations_on_name      (name) UNIQUE
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
FactoryBot.define do
  factory :organisation do
    transient { sequence(:identifier) }

    name { "SAIS Organisation #{identifier}" }
    email { "sais-organisation-#{identifier}@example.com" }
    phone { "01234 567890" }
    ods_code { "U#{identifier}" }
    careplus_venue_code { identifier.to_s }
    privacy_notice_url { "https://example.com/privacy-notice" }
    privacy_policy_url { "https://example.com/privacy-policy" }

    trait :with_one_nurse do
      users { [create(:user, :nurse, organisation: instance)] }
    end

    trait :with_one_admin do
      users { [create(:user, :admin, organisation: instance)] }
    end

    trait :with_generic_clinic do
      after(:create) { |organisation| GenericClinicFactory.call(organisation:) }
    end
  end
end
