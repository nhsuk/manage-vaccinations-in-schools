# == Schema Information
#
# Table name: consent_forms
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :text
#  contact_injection         :boolean
#  contact_method            :integer
#  contact_method_other      :text
#  date_of_birth             :date
#  first_name                :text
#  gp_name                   :string
#  gp_response               :integer
#  health_answers            :jsonb            not null
#  last_name                 :text
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  reason                    :integer
#  reason_notes              :text
#  recorded_at               :datetime
#  response                  :integer
#  use_common_name           :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  consent_id                :bigint
#  session_id                :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_consent_id  (consent_id)
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_id => consents.id)
#  fk_rails_...  (session_id => sessions.id)
#
FactoryBot.define do
  factory :consent_form do
    transient { random { Random.new } }

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    use_common_name { false }
    date_of_birth { Faker::Date.birthday(min_age: 3, max_age: 9) }
    parent_name { Faker::Name.name }
    parent_relationship do
      ConsentForm.parent_relationships.keys.first(2).sample(random:)
    end
    parent_email { Faker::Internet.email name: parent_name }
    parent_phone { "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}" }
    contact_method { "any" }
    response { "given" }
    gp_response { "yes" }
    gp_name { Faker::Name.name }
    address_line_1 { Faker::Address.street_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.postcode }

    # use_common_name { false }

    session
    health_answers do
      [
        HealthAnswer.new(
          id: 0,
          question: "Is there anything we should know?",
          response: "no"
        )
      ]
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
  end
end
