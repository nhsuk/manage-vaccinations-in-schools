# frozen_string_literal: true

# == Schema Information
#
# Table name: consents
#
#  id                  :bigint           not null, primary key
#  health_answers      :jsonb            not null
#  invalidated_at      :datetime
#  notes               :text             default(""), not null
#  notify_parents      :boolean
#  reason_for_refusal  :integer
#  response            :integer          not null
#  route               :integer          not null
#  submitted_at        :datetime         not null
#  vaccine_methods     :integer          default([]), not null, is an Array
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
      health_questions_list do
        questions = programme.vaccines.active.first&.health_questions
        if questions&.any?
          questions.in_order.pluck(:title)
        else
          ["Is there anything else we should know?"]
        end
      end
    end

    programme
    organisation do
      programme.organisations.first ||
        association(:organisation, programmes: [programme])
    end

    patient
    parent do
      patient.parents.first ||
        association(:parent_relationship, patient:).parent
    end

    response { "given" }
    vaccine_methods { %w[injection] }
    route { "website" }

    health_answers do
      health_questions_list.map do |question|
        HealthAnswer.new({ question:, response: "no" })
      end
    end

    submitted_at { consent_form&.recorded_at || Time.current }

    traits_for_enum :vaccine_method

    trait :given_verbally do
      given
      route { "phone" }
      recorded_by
    end

    trait :given_injection do
      given
      vaccine_methods { %w[injection] }
    end

    trait :given_nasal do
      given
      vaccine_methods { %w[nasal] }
    end

    trait :given_nasal_or_injection do
      given
      vaccine_methods { %w[nasal injection] }
    end

    trait :self_consent do
      route { "self_consent" }
      parent { nil }
      notify_parents { false }
    end

    trait :notify_parents do
      notify_parents { true }
    end

    trait :refused do
      response { "refused" }
      reason_for_refusal { "personal_choice" }
      health_answers { [] }
      notes { "Refused." }
      vaccine_methods { [] }
    end

    trait :not_provided do
      response { "not_provided" }
      vaccine_methods { [] }
    end

    trait :from_mum do
      parent do
        patient
          .parent_relationships
          .eager_load(:parent)
          .find(&:mother?)
          &.parent || create(:parent_relationship, :mother, patient:).parent
      end
    end

    trait :from_dad do
      parent do
        patient
          .parent_relationships
          .eager_load(:parent)
          .find(&:father?)
          &.parent || create(:parent_relationship, :father, patient:).parent
      end
    end

    trait :from_granddad do
      parent { create(:parent_relationship, :granddad, patient:).parent }
    end

    trait :health_question_notes do
      health_answers do
        health_questions_list.map do |question|
          if question == health_questions_list.last
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

    trait :withdrawn do
      refused
      withdrawn_at { Time.current }
    end

    trait :invalidated do
      invalidated_at { Time.current }
      notes { "Some notes." }
    end
  end
end
