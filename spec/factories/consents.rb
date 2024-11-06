# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  reason_for_refusal  :integer
#  recorded_at         :datetime
#  response            :integer
#  route               :integer
#  withdrawn_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organisation_id     :bigint           not null
#  parent_id           :bigint
#  patient_id          :bigint           not null
#  programme_id        :bigint           not null
#  recorded_by_user_id :bigint
#
# Indexes
#
#  index_consents_on_organisation_id      (organisation_id)
#  index_consents_on_parent_id            (parent_id)
#  index_consents_on_patient_id           (patient_id)
#  index_consents_on_programme_id         (programme_id)
#  index_consents_on_recorded_by_user_id  (recorded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (parent_id => parents.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (recorded_by_user_id => users.id)
#
FactoryBot.define do
  factory :consent do
    transient do
      health_questions_list { ["Is there anything else we should know?"] }
    end

    programme
    organisation do
      programme.organisations.first ||
        association(:organisation, programmes: [programme])
    end

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

    trait :self_consent do
      route { "self_consent" }
      parent { nil }
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

    trait :withdrawn do
      refused
      withdrawn_at { Time.current }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end
  end
end
