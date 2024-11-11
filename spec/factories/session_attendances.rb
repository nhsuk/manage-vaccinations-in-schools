# frozen_string_literal: true

FactoryBot.define do
  factory :session_attendance do
    patient_session
    session_date { patient_session.session.session_dates.first }

    trait :present do
      attending { true }
    end

    trait :absent do
      attending { false }
    end
  end
end
