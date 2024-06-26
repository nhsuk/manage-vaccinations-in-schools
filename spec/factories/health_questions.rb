# frozen_string_literal: true

# == Schema Information
#
# Table name: health_questions
#
#  id                    :bigint           not null, primary key
#  hint                  :string
#  metadata              :jsonb            not null
#  question              :string
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
    vaccine { create :vaccine, :hpv }

    # HPV vaccine questions
    trait :severe_allergies do
      question { "Does your child have any severe allergies?" }
    end

    trait :medical_conditions do
      question do
        "Does your child have any medical conditions for which they receive treatment?"
      end
    end

    trait :severe_reaction do
      question do
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
      end
    end

    # Flu vaccine questions
    trait :asthma do
      question { "Has your child been diagnosed with asthma?" }
    end

    trait :steroids do
      question { "Have they taken oral steroids in the last 2 weeks?" }
    end

    trait :intensive_care do
      question { "Have they been admitted to intensive care for their asthma?" }
    end

    trait :flu_vaccination do
      question { "Has your child had a flu vaccination in the last 5 months?" }
    end

    trait :immune_system do
      question do
        "Does your child have a disease or treatment that severely affects their immune system?"
      end
      hint do
        "For example, treatment for leukaemia or taking immunosuppressant medication"
      end
    end

    trait :household_immune_system do
      question do
        "Is anyone in your household currently having treatment that severely affects their immune system?"
      end
      hint { "For example, they need to be kept in isolation" }
    end

    trait :egg_allergy do
      question do
        "Has your child ever been admitted to intensive care due to an allergic reaction to egg?"
      end
    end

    trait :allergies do
      question { "Does your child have any allergies to medication?" }
    end

    trait :reaction do
      question do
        "Has your child ever had a reaction to previous vaccinations?"
      end
    end

    trait :aspirin do
      question { "Does you child take regular aspirin?" }
      hint { "Also known as Salicylate therapy" }
    end
  end
end
