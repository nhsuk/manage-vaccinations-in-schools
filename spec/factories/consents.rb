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
#
# Indexes
#
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#
FactoryBot.define do
  factory :consent do
    transient do
      random { Random.new }
      health_questions_list { ["Is there anything else we should know?"] }
    end

    patient
    campaign
    response { "given" }
    route { "website" }
    recorded_at { Time.zone.now }

    parent { patient.parent }

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
      parent do
        if patient.parent.relationship_mother?
          patient.parent
        else
          create(:parent, :mum, last_name: patient.last_name)
        end
      end
    end

    trait :from_dad do
      parent do
        if patient.parent.relationship_father?
          patient.parent
        else
          create(:parent, :dad, last_name: patient.last_name)
        end
      end
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

    trait :from_granddad do
      parent do
        create(
          :parent,
          relationship: :other,
          relationship_other: "Granddad",
          parental_responsibility: "yes",
          last_name: patient.last_name
        )
      end
    end

    trait :draft do
      recorded_at { nil }
      draft_parent { patient.parent.tap { _1.update!(recorded_at: nil) } }
    end
  end
end
