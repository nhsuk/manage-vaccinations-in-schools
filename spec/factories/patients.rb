# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :string
#  date_of_birth             :date
#  first_name                :string
#  last_name                 :string
#  nhs_number                :string
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  sent_consent_at           :datetime
#  sent_reminder_at          :datetime
#  session_reminder_sent_at  :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  registration_id           :bigint
#
# Indexes
#
#  index_patients_on_location_id      (location_id)
#  index_patients_on_nhs_number       (nhs_number) UNIQUE
#  index_patients_on_registration_id  (registration_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#
FactoryBot.define do
  factory :patient do
    transient do
      random { Random.new }

      # Used for associations like consent and triage that need to be
      # associated with a campaign
      session { create :session }
      campaign { session.campaign }
      parent_sex { %w[male female].sample(random:) }
      parent_first_name do
        if parent_sex == "male"
          Faker::Name.masculine_name
        else
          Faker::Name.feminine_name
        end
      end
    end

    nhs_number { Faker::NationalHealthService.british_number.gsub(/\s+/, "") }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday(min_age: 3, max_age: 9) }
    patient_sessions { [] }
    # TODO: We should be taking the location from the session by default. But
    #       this seems to break the example campaign generator by creating
    #       duplicate sessions.
    # location { session&.location }example.com
    parent_name { "#{parent_first_name} #{last_name}" }
    parent_relationship { parent_sex == "male" ? "father" : "mother" }
    parent_email do
      "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@example.com"
    end
    # Replace first two digits with 07 to make it a mobile number
    parent_phone { "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}" }

    trait :of_hpv_vaccination_age do
      date_of_birth { Faker::Date.birthday(min_age: 12, max_age: 13) }
    end

    trait :with_address do
      address_line_1 { Faker::Address.street_address }
      address_line_2 { Faker::Address.secondary_address }
      address_town { Faker::Address.city }
      address_postcode { Faker::Address.postcode }
    end

    trait :consent_given_triage_not_needed do
      after(:create) do |patient, evaluator|
        create(
          :consent,
          :given,
          campaign: evaluator.campaign,
          patient:,
          parent_relationship: patient.parent_relationship
        )
      end
    end

    trait :consent_given_triage_needed do
      after(:create) do |patient, evaluator|
        create(
          :consent,
          :given,
          :health_question_notes,
          campaign: evaluator.campaign,
          patient:
        )
      end
    end

    trait :consent_refused do
      after(:create) do |patient, evaluator|
        create(
          :consent,
          :refused,
          :from_mum,
          campaign: evaluator.campaign,
          patient:
        )
      end
    end

    trait :consent_refused_with_notes do
      after(:create) do |patient, evaluator|
        create(
          :consent,
          :refused,
          :from_mum,
          campaign: evaluator.campaign,
          reason_for_refusal: "already_vaccinated",
          reason_for_refusal_notes: "Already had the vaccine at the GP",
          patient:
        )
      end
    end

    trait :consent_conflicting do
      after(:create) do |patient, evaluator|
        create(
          :consent,
          :refused,
          :from_mum,
          campaign: evaluator.campaign,
          patient:
        )
        create(
          :consent,
          :given,
          :from_dad,
          campaign: evaluator.campaign,
          patient:
        )
      end
    end

    trait :no_parent_info do
      parent_name { nil }
      parent_relationship { nil }
      parent_relationship_other { nil }
      parent_phone { nil }
      parent_email { nil }
    end

    factory :patient_with_consent_given_triage_not_needed do
      patient_sessions { [build(:patient_session, session:)] }

      consents { [build(:consent, :given, campaign:, parent_relationship:)] }
    end

    factory :patient_with_consent_given_triage_needed do
      patient_sessions { [build(:patient_session, session:)] }

      consents do
        [
          build(
            :consent,
            :given,
            :needing_triage,
            campaign:,
            parent_relationship:
          )
        ]
      end
    end

    factory :patient_with_consent_refused do
      patient_sessions do
        [build(:patient_session, session:, state: "consent_refused")]
      end

      consents { [build(:consent, :refused, campaign:, parent_relationship:)] }
    end
  end
end
