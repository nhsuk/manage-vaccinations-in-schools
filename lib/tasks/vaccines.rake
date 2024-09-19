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

  desc "Add a vaccine to a programme."
  task :add_to_programme,
       %i[programme_id vaccine_nivs_name] => :environment do |_, args|
    programme = Programme.find_by(id: args[:programme_id])
    vaccine = Vaccine.find_by(nivs_name: args[:vaccine_nivs_name])

    if programme.nil? || vaccine.nil?
      raise "Could not find programme or vaccine."
    end

    if programme.vaccines.include?(vaccine)
      raise "Vaccine is already part of the programme."
    end

    if vaccine.type != programme.type
      raise "Vaccine is not suitable for this programme type."
    end

    programme.vaccines << vaccine
  end
end
