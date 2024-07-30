# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  method              :integer          not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  supplier            :text             not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_gtin                 (gtin) UNIQUE
#  index_vaccines_on_snomed_product_code  (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term  (snomed_product_term) UNIQUE
#  index_vaccines_on_supplier_and_brand   (supplier,brand) UNIQUE
#
FactoryBot.define do
  factory :vaccine do
    transient { batch_count { 1 } }

    supplier { Faker::Company.name }
    dose { Faker::Number.decimal(l_digits: 0) }
    snomed_product_code { Faker::Number.decimal_part(digits: 17) }
    snomed_product_term { Faker::Lorem.sentence }

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
      supplier { "AstraZeneca UK Ltd" }
      gtin { "05000456078276" }
      snomed_product_code { "27114211000001105" }
      snomed_product_term do
        "Fluenz Tetra vaccine nasal suspension 0.2ml unit dose (AstraZeneca UK Ltd) (product)"
      end
      add_attribute(:method) { :nasal }
      dose { 0.2 }
    end

    trait :quadrivalent_influenza do
      type { "flu" }
      brand { "Quadrivalent Influenza vaccine - QIVe" }
      supplier { "Sanofi" }
      gtin { "3664798046564" }
      snomed_product_code { "34680411000001107" }
      snomed_product_term do
        "Quadrivalent influenza vaccine (split virion, inactivated) suspension" \
          " for injection 0.5ml pre-filled syringes (Sanofi) (product)"
      end
      add_attribute(:method) { :injection }
      dose { 0.5 }
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
      type { "hpv" }
      brand { "Gardasil 9" }
      supplier { "Merck Sharp & Dohme (UK) Ltd" }
      gtin { "00191778001693" }
      snomed_product_code { "33493111000001108" }
      snomed_product_term do
        "Gardasil 9 vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd) (product)"
      end
      add_attribute(:method) { :injection }
      dose { 0.5 }
    end
  end
end
