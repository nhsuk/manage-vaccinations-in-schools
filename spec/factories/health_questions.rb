# frozen_string_literal: true

# == Schema Information
#
# Table name: health_questions
#
#  id                    :bigint           not null, primary key
#  hint                  :string
#  metadata              :jsonb            not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  follow_up_question_id :bigint
#  next_question_id      :bigint
#  vaccine_id            :bigint           not null
#
# Indexes
#
#  index_health_questions_on_follow_up_question_id  (follow_up_question_id)
#  index_health_questions_on_next_question_id       (next_question_id)
#  index_health_questions_on_vaccine_id             (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (follow_up_question_id => health_questions.id)
#  fk_rails_...  (next_question_id => health_questions.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
FactoryBot.define do
  factory :health_question do
    vaccine
    title { Faker::Lorem.question }

    trait :for_hpv_vaccine do
      vaccine { association :vaccine, :hpv }
    end

    trait :for_flu_vaccine do
      vaccine { association :vaccine, :flu }
    end

    # HPV vaccine questions
    trait :severe_allergies do
      for_hpv_vaccine
      title { "Does your child have any severe allergies?" }
    end

    trait :medical_conditions do
      for_hpv_vaccine
      title do
        "Does your child have any medical conditions for which they receive treatment?"
      end
    end

    trait :severe_reaction do
      for_hpv_vaccine
      title do
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
      end
    end

    # Flu vaccine questions
    trait :asthma do
      for_flu_vaccine
      title { "Has your child been diagnosed with asthma?" }
    end

    trait :steroids do
      for_flu_vaccine
      title { "Have they taken oral steroids in the last 2 weeks?" }
    end

    trait :intensive_care do
      for_flu_vaccine
      title { "Have they been admitted to intensive care for their asthma?" }
    end

    trait :flu_vaccination do
      for_flu_vaccine
      title { "Has your child had a flu vaccination in the last 5 months?" }
    end

    trait :immune_system do
      for_flu_vaccine
      title do
        "Does your child have a disease or treatment that severely affects their immune system?"
      end
      hint do
        "For example, treatment for leukaemia or taking immunosuppressant medication"
      end
    end

    trait :household_immune_system do
      for_flu_vaccine
      title do
        "Is anyone in your household currently having treatment that severely affects their immune system?"
      end
      hint { "For example, they need to be kept in isolation" }
    end

    trait :egg_allergy do
      for_flu_vaccine
      title do
        "Has your child ever been admitted to intensive care due to an allergic reaction to egg?"
      end
    end

    trait :allergies do
      for_flu_vaccine
      title { "Does your child have any allergies to medication?" }
    end

    trait :reaction do
      for_flu_vaccine
      title { "Has your child ever had a reaction to previous vaccinations?" }
    end

    trait :aspirin do
      for_flu_vaccine
      title { "Does you child take regular aspirin?" }
      hint { "Also known as Salicylate therapy" }
    end
  end
end
