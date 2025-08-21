# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :bigint           not null, primary key
#  careplus_venue_code           :string           not null
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  phone                         :string
#  phone_instructions            :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  workgroup                     :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  organisation_id               :bigint           not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_teams_on_name             (name) UNIQUE
#  index_teams_on_organisation_id  (organisation_id)
#  index_teams_on_workgroup        (workgroup) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
FactoryBot.define do
  factory :team do
    transient do
      sequence(:identifier)
      ods_code { generate(:ods_code) }
    end

    organisation { association(:organisation, ods_code:) }

    workgroup { "w#{identifier}" }
    name { "SAIS Team #{identifier}" }
    email { "sais-team-#{identifier}@example.com" }
    phone { "01234 567890" }
    careplus_venue_code { identifier.to_s }
    privacy_notice_url { "https://example.com/privacy-notice" }
    privacy_policy_url { "https://example.com/privacy-policy" }

    trait :with_one_nurse do
      users { [create(:user, :nurse, team: instance)] }
    end

    trait :with_one_admin do
      users { [create(:user, :admin, team: instance)] }
    end

    trait :with_generic_clinic do
      after(:create) { |team| GenericClinicFactory.call(team:) }
    end
  end
end
