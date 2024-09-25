# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  active                    :boolean          default(FALSE), not null
#  close_consent_at          :date
#  send_consent_reminders_at :date
#  send_consent_requests_at  :date
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  team_id                   :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id  (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :session do
    transient do
      date { Date.current }
      programme { association :programme }
    end

    programmes { [programme] }
    team { programmes.first&.team || association(:team) }
    location { association :location, :school }

    send_consent_requests_at { date - 14.days }
    send_consent_reminders_at { send_consent_requests_at + 7.days }
    close_consent_at { date }

    active { true }

    after(:create) do |session, evaluator|
      next if (date = evaluator.date).nil?
      create(:session_date, session:, value: date)
    end

    trait :draft do
      active { false }
    end

    trait :in_progress do
      date { Time.zone.now }
    end

    trait :in_future do
      date { Time.zone.now + 1.week }
    end

    trait :in_past do
      date { Time.zone.now - 1.week }
    end

    trait :minimal do
      send_consent_requests_at { nil }
      send_consent_reminders_at { nil }
      close_consent_at { nil }
    end
  end
end
