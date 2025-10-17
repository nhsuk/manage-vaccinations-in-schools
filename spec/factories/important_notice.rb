# frozen_string_literal: true

FactoryBot.define do
  factory :important_notice do
    patient
    team_id { create(:team).id }

    notice_type { :deceased }
    date_time { Time.current }
    message { "Record updated with child’s date of death" }
    can_dismiss { false }

    trait :deceased do
      notice_type { :deceased }
      message { "Record updated with child’s date of death" }
    end

    trait :restricted do
      notice_type { :restricted }
      message { "Record flagged as sensitive" }
    end

    trait :invalidated do
      notice_type { :invalidated }
      message { "Record flagged as invalid" }
    end

    trait :gillick_no_notify do
      notice_type { :gillick_no_notify }
      message do
        "The child gave consent under Gillick competence and does not want their parents to be notified."
      end
      vaccination_record
    end

    trait :dismissed do
      dismissed_at { 1.day.ago }
      dismissed_by_user { association :user }
    end

    trait :dismissible do
      can_dismiss { true }
    end
  end
end
