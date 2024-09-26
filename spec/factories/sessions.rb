# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  academic_year             :integer          not null
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

    academic_year { (date || Date.current).academic_year }
    programmes { [programme] }
    team { programmes.first&.team || association(:team) }
    location { association :location, :school, team: }

    send_consent_requests_at { date - 14.days if date }
    send_consent_reminders_at do
      send_consent_requests_at + 7.days if send_consent_requests_at
    end
    close_consent_at { date }

    after(:create) do |session, evaluator|
      next if (date = evaluator.date).nil?
      create(:session_date, session:, value: date)
    end

    trait :today do
      date { Date.current }
    end

    trait :unscheduled do
      date { nil }
    end

    trait :scheduled do
      date { Date.current + 1.week }
    end

    trait :completed do
      date { Date.current - 1.week }
    end

    trait :minimal do
      send_consent_requests_at { nil }
      send_consent_reminders_at { nil }
      close_consent_at { nil }
    end
  end
end
