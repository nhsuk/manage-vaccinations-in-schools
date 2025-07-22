# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  days_before_consent_reminders :integer
#  requires_registration         :boolean          default(TRUE), not null
#  send_consent_requests_at      :date
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_sessions_on_location_id              (location_id)
#  index_sessions_on_team_id_and_location_id  (team_id,location_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :session do
    transient do
      date { Date.current }
      dates { [] }
      subteam { association(:subteam, team:) }
    end

    sequence(:slug) { |n| "session-#{n}" }

    academic_year { (date || Date.current).academic_year }
    programmes { [association(:programme)] }
    team { association(:team, programmes:) }
    location { association(:school, subteam:, programmes:) }

    days_before_consent_reminders do
      team.days_before_consent_reminders if date && !location.generic_clinic?
    end
    send_consent_requests_at do
      if date && !location.generic_clinic?
        (date - team.days_before_consent_requests.days)
      end
    end
    send_invitations_at do
      if date && location.generic_clinic?
        (date - team.days_before_invitations.days)
      end
    end

    session_dates do
      if dates.present?
        dates.map { build(:session_date, session: instance, value: _1) }
      elsif date.present?
        [build(:session_date, session: instance, value: date)]
      else
        []
      end
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

    trait :requires_no_registration do
      requires_registration { false }
    end
  end
end
