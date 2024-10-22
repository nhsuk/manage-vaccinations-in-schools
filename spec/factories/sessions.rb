# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  closed_at                     :datetime
#  days_before_consent_reminders :integer
#  send_consent_requests_at      :date
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id                                    (team_id)
#  index_sessions_on_team_id_and_location_id_and_academic_year  (team_id,location_id,academic_year) UNIQUE
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
    team { association(:team, programmes:) }
    location { association :location, :school, team: }

    days_before_consent_reminders { team.days_before_consent_reminders if date }
    send_consent_requests_at do
      (date - team.days_before_consent_requests.days) if date
    end

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
      closed
      date { Date.current - 1.week }
    end

    trait :closed do
      closed_at { Time.current }
    end
  end
end
