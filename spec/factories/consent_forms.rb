# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_forms
#
#  id                                  :bigint           not null, primary key
#  academic_year                       :integer          not null
#  address_line_1                      :string
#  address_line_2                      :string
#  address_postcode                    :string
#  address_town                        :string
#  archived_at                         :datetime
#  date_of_birth                       :date
#  education_setting                   :integer
#  family_name                         :text
#  given_name                          :text
#  health_answers                      :jsonb            not null
#  nhs_number                          :string
#  notes                               :text             default(""), not null
#  parent_contact_method_other_details :string
#  parent_contact_method_type          :string
#  parent_email                        :string
#  parent_full_name                    :string
#  parent_phone                        :string
#  parent_phone_receive_updates        :boolean          default(FALSE), not null
#  parent_relationship_other_name      :string
#  parent_relationship_type            :string
#  preferred_family_name               :string
#  preferred_given_name                :string
#  recorded_at                         :datetime
#  school_confirmed                    :boolean
#  use_preferred_name                  :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  location_id                         :bigint           not null
#  school_id                           :bigint
#  team_id                             :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_academic_year  (academic_year)
#  index_consent_forms_on_location_id    (location_id)
#  index_consent_forms_on_nhs_number     (nhs_number)
#  index_consent_forms_on_school_id      (school_id)
#  index_consent_forms_on_team_id        (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  factory :consent_form do
    transient do
      session { association :session }
      programmes { session.programmes }
      response { "given" }
      reason_for_refusal { nil }
      reason_for_refusal_notes { "" }
      without_gelatine { false }
    end

    given_name { Faker::Name.first_name }
    family_name { Faker::Name.last_name }
    use_preferred_name { false }
    date_of_birth { Faker::Date.birthday(min_age: 3, max_age: 9) }
    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }
    academic_year { session.academic_year }

    parent_email { Faker::Internet.email }
    parent_full_name { "#{Faker::Name.first_name} #{family_name}" }
    parent_phone { "07700 900#{rand(0..999).to_s.rjust(3, "0")}" }
    parent_phone_receive_updates { parent_phone.present? }

    parent_relationship_type { ParentRelationship.types.keys.sample }
    parent_relationship_other_name do
      parent_relationship_type == "other" ? "Other" : nil
    end

    parent_contact_method_type do
      Parent.contact_method_types.keys.sample if parent_phone.present?
    end
    parent_contact_method_other_details do
      parent_contact_method_type == "other" ? "Other details." : nil
    end

    parental_responsibility { "yes" }

    team { session.team }
    location { session.location }
    school { location.school? ? location : association(:school, team:) }
    school_confirmed { true }

    health_answers do
      [
        HealthAnswer.new(
          id: 0,
          question: "Is there anything we should know?",
          response: "no"
        )
      ]
    end

    after(:build) do |consent_form, evaluator|
      evaluator.programmes.each do |programme|
        consent_form.consent_form_programmes.build(programme:)
      end
    end

    trait :archived do
      archived_at { Time.current }
    end

    trait :given do
      response { "given" }
    end

    trait :refused do
      response { "refused" }
      reason_for_refusal { "personal_choice" }
      health_answers { [] }
    end

    trait :education_setting_home do
      education_setting { "home" }
      school { nil }
      school_confirmed { false }
    end

    after(:create) do |consent_form, evaluator|
      vaccine_methods = evaluator.response == "given" ? %w[injection] : []
      without_gelatine = evaluator.without_gelatine

      consent_form.consent_form_programmes.update_all(
        notes: evaluator.reason_for_refusal_notes,
        reason_for_refusal: evaluator.reason_for_refusal,
        response: evaluator.response,
        vaccine_methods:,
        without_gelatine:
      )
    end

    trait :with_health_answers_no_branching do
      health_answers do
        [
          HealthAnswer.new(
            id: 0,
            question:
              "Does the child have any severe allergies that have led to an anaphylactic reaction?",
            next_question: 1,
            response: "no"
          ),
          HealthAnswer.new(
            id: 1,
            question: "Does the child have any existing medical conditions?",
            next_question: 2,
            response: "no"
          ),
          HealthAnswer.new(
            id: 2,
            question: "Does the child take any regular medication?",
            response: "no"
          )
        ]
      end
    end

    trait :with_health_answers_asthma_branching do
      health_answers do
        [
          HealthAnswer.new(
            id: 0,
            question: "Has your child been diagnosed with asthma?",
            next_question: 2,
            follow_up_question: 1,
            response: "yes",
            notes: "Notes",
            would_require_triage: false
          ),
          HealthAnswer.new(
            id: 1,
            question: "Have they taken oral steroids in the last 2 weeks?",
            next_question: 2,
            response: "no"
          ),
          HealthAnswer.new(
            id: 2,
            question:
              "Has your child had a flu vaccination in the last 5 months?",
            response: "no"
          )
        ]
      end
    end

    trait :recorded do
      recorded_at { Time.zone.now }
    end

    trait :draft do
      recorded_at { nil }
    end
  end
end
