# == Schema Information
#
# Table name: consents
#
#  id                          :bigint           not null, primary key
#  health_answers              :jsonb
#  parent_contact_method       :integer
#  parent_contact_method_other :text
#  parent_email                :text
#  parent_name                 :text
#  parent_phone                :text
#  parent_relationship         :integer
#  parent_relationship_other   :text
#  reason_for_refusal          :integer
#  reason_for_refusal_notes    :text
#  recorded_at                 :datetime
#  response                    :integer
#  route                       :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campaign_id                 :bigint           not null
#  patient_id                  :bigint           not null
#  recorded_by_user_id         :bigint
#
# Indexes
#
#  index_consents_on_campaign_id          (campaign_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#
FactoryBot.define do
  factory :consent do
    transient do
      random { Random.new }
      health_questions_list { ["Is there anything else we should know?"] }
    end

    patient { create(:patient) }
    campaign { create(:campaign) }
    response { "given" }
    route { "website" }
    recorded_at { Time.zone.now }

    parent_name { patient.parent.name }
    parent_email { patient.parent.email }
    parent_phone { patient.parent.phone }
    parent_relationship { patient.parent.relationship }
    parent_relationship_other { patient.parent.relationship_other }

    health_answers do
      health_questions_list.map do |question|
        HealthAnswer.new({ question:, response: "no" })
      end
    end

    factory :consent_given do
      response { :given }
    end

    trait :given_verbally do
      route { "phone" }
      recorded_by { create(:user) }
    end

    trait :refused do
      response { :refused }
      reason_for_refusal { :personal_choice }
      health_answers { [] }
    end

    factory :consent_refused do
      refused
    end

    trait :from_mum do
      parent_relationship { "mother" }
      parent_name do
        if patient.parent.relationship == "mother"
          patient.parent.name
        else
          "#{Faker::Name.female_first_name} #{patient.last_name}"
        end
      end
      parent_email do
        if patient.parent.relationship == "mother"
          patient.parent.email
        else
          "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@example.com"
        end
      end
      parent_phone do
        if patient.parent.relationship == "mother"
          patient.parent.phone
        else
          "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}"
        end
      end
    end

    trait :from_dad do
      parent_relationship { "father" }
      parent_name do
        if patient.parent.relationship == "father"
          patient.parent.name
        else
          "#{Faker::Name.male_first_name} #{patient.last_name}"
        end
      end
      parent_email do
        if patient.parent.relationship == "father"
          patient.parent.email
        else
          "#{parent_name.downcase.gsub(" ", ".")}#{random.rand(100)}@example.com"
        end
      end
      parent_phone do
        if patient.parent.relationship == "father"
          patient.parent.phone
        else
          "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}"
        end
      end
    end

    trait :from_granddad do
      parent_relationship { "other" }
      parent_relationship_other { "Granddad" }
    end

    trait :health_question_notes do
      health_answers do
        health_questions_list.map do |question|
          if question == "Is there anything else we should know?"
            HealthAnswer.new(
              question:,
              response: "yes",
              notes: "The child has a severe egg allergy"
            )
          else
            HealthAnswer.new(question:, response: "no")
          end
        end
      end
    end

    trait :no_contraindications do
      health_answers do
        health_questions_list.map do
          HealthAnswer.new(question: _1, response: "no")
        end
      end
    end

    trait :needing_triage do
      health_question_notes
    end
  end
end
