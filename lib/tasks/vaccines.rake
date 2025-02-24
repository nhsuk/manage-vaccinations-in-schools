# frozen_string_literal: true

namespace :vaccines do
  desc "Seed the vaccine table from the built-in vaccine data."
  task :seed, %i[type] => :environment do |_task, args|
    type = args[:type]

    all_data = YAML.load_file(Rails.root.join("config/vaccines.yml"))

    all_data.each_value do |data|
      next if type.present? && data["type"] != type

      programme = Programme.find_or_create_by!(type: data["type"])

      vaccine =
        Vaccine.find_or_initialize_by(
          snomed_product_code: data["snomed_product_code"]
        )

      vaccine.brand = data["brand"]
      vaccine.discontinued = data.fetch("discontinued", false)
      vaccine.dose_volume_ml = data["dose_volume_ml"]
      vaccine.manufacturer = data["manufacturer"]
      vaccine.method = data["method"]
      vaccine.nivs_name = data["nivs_name"]
      vaccine.snomed_product_term = data["snomed_product_term"]
      vaccine.programme = programme

      vaccine.save!

      next if vaccine.health_questions.exists?

      if programme.hpv?
        create_hpv_health_questions(vaccine)
      elsif programme.menacwy?
        create_menacwy_health_questions(vaccine)
      elsif programme.td_ipv?
        create_td_ipv_health_questions(vaccine)
      end
    end
  end
end

def create_hpv_health_questions(vaccine)
  vaccine.health_questions.create!(
    title: "Does your child have any severe allergies?",
    next_question:
      vaccine.health_questions.create!(
        title:
          "Does your child have any medical conditions for which they receive treatment?",
        next_question:
          vaccine.health_questions.create!(
            title:
              "Has your child ever had a severe reaction to any medicines, including vaccines?",
            next_question:
              vaccine.health_questions.create!(
                title:
                  "Does your child need extra support during vaccination sessions?",
                hint: "For example, they’re autistic, or extremely anxious"
              )
          )
      )
  )
end

def create_menacwy_health_questions(vaccine)
  vaccine.health_questions.create!(
    title:
      "Does your child have a bleeding disorder or another medical condition they receive treatment for?",
    next_question:
      vaccine.health_questions.create!(
        title: "Does your child have any severe allergies?",
        next_question:
          vaccine.health_questions.create!(
            title:
              "Has your child ever had a severe reaction to any medicines, including vaccines?",
            next_question:
              vaccine.health_questions.create!(
                title:
                  "Has your child had a meningitis (MenACWY) vaccination in the last 5 years?",
                hint:
                  "It’s usually given once in Year 9 or 10. Some children may have had it before travelling abroad.",
                next_question:
                  vaccine.health_questions.create!(
                    title:
                      "Does your child need extra support during vaccination sessions?",
                    hint: "For example, they’re autistic, or extremely anxious"
                  )
              )
          )
      )
  )
end

def create_td_ipv_health_questions(vaccine)
  vaccine.health_questions.create!(
    title:
      "Does your child have a bleeding disorder or another medical condition they receive treatment for?",
    next_question:
      vaccine.health_questions.create!(
        title: "Does your child have any severe allergies?",
        next_question:
          vaccine.health_questions.create!(
            title:
              "Has your child ever had a severe reaction to any medicines, including vaccines?",
            next_question:
              vaccine.health_questions.create!(
                title:
                  "Has your child had a tetanus, diphtheria and polio vaccination in the last 5 years?",
                hint:
                  "Most children will not have had this vaccination since their 4-in-1 pre-school booster",
                next_question:
                  vaccine.health_questions.create!(
                    title:
                      "Does your child need extra support during vaccination sessions?",
                    hint: "For example, they’re autistic, or extremely anxious"
                  )
              )
          )
      )
  )
end
