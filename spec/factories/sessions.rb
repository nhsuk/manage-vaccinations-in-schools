# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                :bigint           not null, primary key
#  close_consent_at  :date
#  date              :date
#  draft             :boolean          default(FALSE)
#  send_consent_at   :date
#  send_reminders_at :date
#  time_of_day       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :bigint
#  imported_from_id  :bigint
#  location_id       :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id       (campaign_id)
#  index_sessions_on_imported_from_id  (imported_from_id)
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#
FactoryBot.define do
  factory :session do
    transient { patients_in_session { 0 } }

    campaign { association :campaign }
    location

    date { Time.zone.today }
    send_consent_at { date - 14.days }
    send_reminders_at { send_consent_at + 7.days }
    close_consent_at { date }

    time_of_day { %w[morning afternoon all_day].sample }

    trait :in_progress do
      date { Time.zone.now }
    end

    trait :in_future do
      date { Time.zone.now + 1.week }
    end

    trait :in_past do
      date { Time.zone.now - 1.week }
    end

    patients do
      create_list(
        :patient,
        patients_in_session,
        sessions: [instance],
        school: instance.location
      )
    end
  end
end
