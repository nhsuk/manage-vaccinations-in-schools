# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                       :bigint           not null, primary key
#  address_line_1           :string
#  address_line_2           :string
#  address_postcode         :string
#  address_town             :string
#  common_name              :string
#  date_of_birth            :date
#  first_name               :string
#  gender_code              :integer          default("not_known"), not null
#  home_educated            :boolean
#  last_name                :string
#  nhs_number               :string
#  pending_changes          :jsonb            not null
#  sent_consent_at          :datetime
#  sent_reminder_at         :datetime
#  session_reminder_sent_at :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  school_id                :bigint
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#  index_patients_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => locations.id)
#

require_relative "../support/faker/national_health_service"

FactoryBot.define do
  factory :patient do
    transient do
      # Used for associations like consent and triage that need to be
      # associated with a programme
      session { nil }
      programme { session&.programme }
    end

    nhs_number { Faker::NationalHealthService.test_number.gsub(/\s+/, "") }

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday(min_age: 12, max_age: 13) }
    school { session&.location }
    parents { [create(:parent, last_name:)] }

    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.postcode }

    after(:create) do |patient, evaluator|
      if evaluator.session
        create(:patient_session, patient:, session: evaluator.session)
      end
    end

    trait :home_educated do
      school { nil }
      home_educated { true }
    end

    trait :consent_given_triage_not_needed do
      consents { [association(:consent, :given, programme:)] }
    end

    trait :consent_given_triage_needed do
      consents do
        [association(:consent, :given, :health_question_notes, programme:)]
      end
    end

    trait :consent_refused do
      consents { [association(:consent, :refused, :from_mum, programme:)] }
    end

    trait :consent_refused_with_notes do
      consents do
        [
          association(
            :consent,
            :refused,
            :from_mum,
            programme:,
            reason_for_refusal: "already_vaccinated",
            reason_for_refusal_notes: "Already had the vaccine at the GP"
          )
        ]
      end
    end

    trait :consent_conflicting do
      consents do
        [
          association(:consent, :refused, :from_mum, programme:),
          association(:consent, :given, :from_dad, programme:)
        ]
      end
    end
  end
end
