# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  consent                   :integer
#  dob                       :date
#  first_name                :text
#  last_name                 :text
#  nhs_number                :bigint
#  parent_email              :text
#  parent_info_source        :text
#  parent_name               :text
#  parent_phone              :text
#  parent_relationship       :integer
#  parent_relationship_other :text
#  preferred_name            :text
#  screening                 :integer
#  seen                      :integer
#  sex                       :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
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
    sex { %w[Male Female].sample(random:) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    screening { "Approved for vaccination" }
    consent { "Parental consent (digital)" }
    seen { "Not yet" }
    dob { Faker::Date.birthday(min_age: 3, max_age: 9) }
    patient_sessions { [] }
    parent_name { "#{parent_first_name} #{last_name}" }
    parent_relationship { parent_sex == "male" ? "father" : "mother" }
    parent_email do
      "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@gmail.com"
    end
    # Replace first two digits with 07 to make it a mobile number
    parent_phone { Faker::PhoneNumber.cell_phone }
    parent_info_source { "school" }

    trait :of_hpv_vaccination_age do
      dob { Faker::Date.birthday(min_age: 12, max_age: 13) }
    end

    trait :consent_given_triage_not_needed do
      after(:create) do |patient, evaluator|
        create(:consent, :given, campaign: evaluator.campaign, patient:)
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
      parent_info_source { nil }
    end
  end
end
