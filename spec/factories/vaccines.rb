# == Schema Information
#
# Table name: vaccines
#
#  id         :bigint           not null, primary key
#  brand      :text
#  gtin       :text
#  method     :integer
#  supplier   :text
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :vaccine do
    transient { batch_count { 1 } }

    after(:create) do |vaccine, evaluator|
      create_list(:batch, evaluator.batch_count, vaccine:)
    end

    trait :flu do
      fluenz_tetra

      after(:create) do |vaccine|
        asthma = create(:health_question, :asthma, vaccine:)
        steroids = create(:health_question, :steroids, vaccine:)
        intensive_care = create(:health_question, :intensive_care, vaccine:)
        flu_vaccination = create(:health_question, :flu_vaccination, vaccine:)
        immune_system = create(:health_question, :immune_system, vaccine:)
        household_immune_system =
          create(:health_question, :household_immune_system, vaccine:)
        egg_allergy = create(:health_question, :egg_allergy, vaccine:)
        allergies = create(:health_question, :allergies, vaccine:)
        reaction = create(:health_question, :reaction, vaccine:)
        aspirin = create(:health_question, :aspirin, vaccine:)

        asthma.update! next_question: flu_vaccination
        asthma.update! follow_up_question: steroids
        steroids.update! next_question: intensive_care
        intensive_care.update! next_question: flu_vaccination

        flu_vaccination.update! next_question: immune_system
        immune_system.update! next_question: household_immune_system
        household_immune_system.update! next_question: egg_allergy
        egg_allergy.update! next_question: allergies
        allergies.update! next_question: reaction
        reaction.update! next_question: aspirin
      end
    end

    trait :fluenz_tetra do
      type { "flu" }
      brand { "Fluenz Tetra" }
      supplier { "AstraZeneca UK Ltd)" }
      gtin { "05000456078276" }
      add_attribute(:method) { :nasal }
    end

    trait :fluerix_tetra do
      type { "flu" }
      brand { "Fluerix Tetra" }
      supplier { "GlaxoSmithKline UK Ltd" }
      gtin { "5000123114115" }
      add_attribute(:method) { :injection }
    end

    trait :hpv do
      gardasil_9

      after(:create) do |vaccine|
        severe_allergies = create(:health_question, :severe_allergies, vaccine:)
        medical_conditions =
          create(:health_question, :medical_conditions, vaccine:)
        severe_reaction = create(:health_question, :severe_reaction, vaccine:)

        severe_allergies.update! next_question: medical_conditions
        medical_conditions.update! next_question: severe_reaction
      end
    end

    trait :gardasil_9 do
      type { "HPV" }
      brand { "Gardasil 9" }
      supplier { "Merck Sharp & Dohme (UK) Ltd" }
      gtin { "00191778001693" }
      add_attribute(:method) { :injection }
    end
  end
end
