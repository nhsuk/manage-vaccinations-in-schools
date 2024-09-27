# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                       :bigint           not null, primary key
#  health_answers           :jsonb
#  reason_for_refusal       :integer
#  reason_for_refusal_notes :text
#  recorded_at              :datetime
#  response                 :integer
#  route                    :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  parent_id                :bigint
#  patient_id               :bigint           not null
#  programme_id             :bigint           not null
#  recorded_by_user_id      :bigint
#  team_id                  :bigint           not null
#
# Indexes
#
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#  index_consents_on_team_id              (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :consent do
    transient do
      health_questions_list { ["Is there anything else we should know?"] }
    end

    programme
    team { programme.team }

    patient
    parent { patient.parents.first }

    response { "given" }
    route { "website" }

    health_answers do
      health_questions_list.map do |question|
        HealthAnswer.new({ question:, response: "no" })
      end
    end

    trait :given do
      response { :given }
    end

    trait :given_verbally do
      given
      route { "phone" }
      recorded_by { create(:user) }
    end

    trait :refused do
      response { :refused }
      reason_for_refusal { :personal_choice }
      health_answers { [] }
    end

    trait :from_mum do
      parent do
        patient.parent_relationships.find(&:mother?)&.parent ||
          create(:parent_relationship, :mother, patient:).parent
      end
    end

    trait :from_dad do
      parent do
        patient.parent_relationships.find(&:father?)&.parent ||
          create(:parent_relationship, :father, patient:).parent
      end
    end

    trait :from_granddad do
      parent { create(:parent_relationship, :granddad, patient:).parent }
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

    trait :recorded do
      recorded_at { Time.zone.now }
    end

    trait :draft do
      recorded_at { nil }
    end
  end
end
