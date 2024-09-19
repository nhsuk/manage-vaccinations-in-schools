# frozen_string_literal: true

namespace :vaccines do
  desc "Seed the vaccine table from the built-in vaccine data."
  task seed: :environment do
    all_data = YAML.load_file(Rails.root.join("config/vaccines.yml"))

    all_data.each_value do |data|
      vaccine =
        Vaccine.find_or_initialize_by(
          snomed_product_code: data["snomed_product_code"]
        )

      vaccine.brand = data["brand"]
      vaccine.discontinued = data.fetch("discontinued", false)
      vaccine.dose = data["dose"]
      vaccine.manufacturer = data["manufacturer"]
      vaccine.method = data["method"]
      vaccine.nivs_name = data["nivs_name"]
      vaccine.snomed_product_term = data["snomed_product_term"]
      vaccine.type = data["type"]

      vaccine.save!

      next if vaccine.flu? || vaccine.health_questions.exists?

      vaccine.health_questions.create!(
        title: "Does your child have any severe allergies?",
        next_question:
          vaccine.health_questions.create!(
            title:
              "Does your child have any medical conditions for which they receive treatment?",
            next_question:
              vaccine.health_questions.create!(
                title:
                  "Has your child ever had a severe reaction to any medicines, including vaccines?"
              )
          )
      )
    end
  end
end
