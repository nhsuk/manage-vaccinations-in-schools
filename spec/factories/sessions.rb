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
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  organisation_id               :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_location_id_academic_year_3496b72d0c  (organisation_id,location_id,academic_year) UNIQUE
#  index_sessions_on_organisation_id                            (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
FactoryBot.define do
  factory :session do
    transient do
      date { Date.current }
      dates { [] }
      programme { association :programme }
    end

    sequence(:slug, &:to_s)

    academic_year { (date || Date.current).academic_year }
    programmes { [programme] }
    team { association(:team, programmes:) }
    location { association :location, :school, team: }

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

    trait :closed do
      closed_at { Time.current }
    end
  end
end
