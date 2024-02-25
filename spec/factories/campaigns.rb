# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :campaign do
    team
    hpv

    trait :hpv do
      name { "HPV" }
      vaccines { [create(:vaccine, :gardasil_9)] }

      after :create do |campaign|
        vaccine = campaign.vaccines.first

        if vaccine.health_questions.empty?
          question_texts = [
            "Does your child have any severe allergies?",
            "Does your child have any medical conditions for which they receive treatment?",
            "Has your child ever had a severe reaction to any medicines, including vaccines?"
          ]
          questions =
            question_texts.map do |text|
              vaccine.health_questions.create!(question: text)
            end

          questions.each_cons(2) do |first_q, next_q|
            first_q.update!(next_question: next_q)
          end
        end
      end
    end

    trait :flu do
      name { "Flu" }
      vaccines do
        [create(:vaccine, :fluenz_tetra), create(:vaccine, :fluerix_tetra)]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [create(:vaccine, :fluenz_tetra)] }
    end
  end
end
