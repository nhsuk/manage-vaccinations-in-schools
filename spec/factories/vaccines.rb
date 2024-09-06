# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  discontinued        :boolean          default(FALSE), not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_gtin                    (gtin) UNIQUE
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_nivs_name               (nivs_name) UNIQUE
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#
FactoryBot.define do
  factory :vaccine do
    transient { batch_count { 1 } }

    type { %w[flu hpv].sample }
    brand { Faker::Commerce.product_name }
    manufacturer { Faker::Company.name }
    sequence(:nivs_name) { |n| "#{brand.parameterize}-#{n}" }
    dose { Faker::Number.decimal(l_digits: 0) }
    snomed_product_code { Faker::Number.decimal_part(digits: 17) }
    snomed_product_term { Faker::Lorem.sentence }
    add_attribute(:method) { %i[nasal injection].sample }

    traits_for_enum :method

    after(:create) do |vaccine, evaluator|
      create_list(:batch, evaluator.batch_count, vaccine:)
    end

    trait :discontinued do
      discontinued { true }
    end

    trait :flu do
      type { "flu" }

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

    trait :hpv do
      type { "hpv" }

      after(:create) do |vaccine|
        severe_allergies = create(:health_question, :severe_allergies, vaccine:)
        medical_conditions =
          create(:health_question, :medical_conditions, vaccine:)
        severe_reaction = create(:health_question, :severe_reaction, vaccine:)

        severe_allergies.update! next_question: medical_conditions
        medical_conditions.update! next_question: severe_reaction
      end
    end

    all_data = YAML.load_file(Rails.root.join("config/vaccines.yml"))

    all_data.each do |key, data|
      trait key do
        send(data["type"])
        brand { data["brand"] }
        discontinued { data.fetch("discontinued", false) }
        dose { data["dose"] }
        manufacturer { data["manufacturer"] }
        add_attribute(:method) { data["method"] }
        nivs_name { data["nivs_name"] }
        snomed_product_code { data["snomed_product_code"] }
        snomed_product_term { data["snomed_product_term"] }
      end
    end
  end
end
