# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_forms
#
#  id                                  :bigint           not null, primary key
#  address_line_1                      :string
#  address_line_2                      :string
#  address_postcode                    :string
#  address_town                        :string
#  contact_injection                   :boolean
#  date_of_birth                       :date
#  education_setting                   :integer
#  family_name                         :text
#  given_name                          :text
#  gp_name                             :string
#  gp_response                         :integer
#  health_answers                      :jsonb            not null
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
#  reason                              :integer
#  reason_notes                        :text
#  recorded_at                         :datetime
#  response                            :integer
#  school_confirmed                    :boolean
#  use_preferred_name                  :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  consent_id                          :bigint
#  location_id                         :bigint           not null
#  organisation_id                     :bigint           not null
#  programme_id                        :bigint           not null
#  school_id                           :bigint
#
# Indexes
#
#  index_consent_forms_on_consent_id       (consent_id)
#  index_consent_forms_on_location_id      (location_id)
#  index_consent_forms_on_organisation_id  (organisation_id)
#  index_consent_forms_on_programme_id     (programme_id)
#  index_consent_forms_on_school_id        (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (school_id => locations.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  factory :consent_form do
    transient { session { association :session } }

    given_name { Faker::Name.first_name }
    family_name { Faker::Name.last_name }
    use_preferred_name { false }
    date_of_birth { Faker::Date.birthday(min_age: 3, max_age: 9) }
    response { "given" }
    school_confirmed { true }
    gp_response { "yes" }
    gp_name { Faker::Name.name }
    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    parent_email { Faker::Internet.email }
    parent_full_name { "#{Faker::Name.first_name} #{family_name}" }
    parent_phone { "07700 900#{rand(0..999).to_s.rjust(3, "0")}" }
    parent_phone_receive_updates { parent_phone.present? }
    parent_relationship_other_name do
      parent_relationship_type == "other" ? "Other" : nil
    end
    parent_relationship_type { ParentRelationship.types.keys.sample }
    parent_contact_method_type { Parent.contact_method_types.keys.sample }
    parent_contact_method_other_details do
      parent_contact_method_type == "other" ? "Other details." : nil
    end
    parental_responsibility { "yes" }

    programme { session.programmes.first }
    team { session.team }
    location { session.location }

    health_answers do
      [
        HealthAnswer.new(
          id: 0,
          question: "Is there anything we should know?",
          response: "no"
        )
      ]
    end

    trait :refused do
      response { :refused }
      reason { :personal_choice }
      health_answers { [] }
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
            notes: "Notes"
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
