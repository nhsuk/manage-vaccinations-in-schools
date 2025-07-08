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

      vaccine.side_effects = side_effects_for(programme, data["method"])

      vaccine.save!

      next if vaccine.health_questions.exists?

      ActiveRecord::Base.transaction do
        if programme.flu?
          create_flu_health_questions(vaccine)
        elsif programme.hpv?
          create_hpv_health_questions(vaccine)
        elsif programme.menacwy?
          create_menacwy_health_questions(vaccine)
        elsif programme.td_ipv?
          create_td_ipv_health_questions(vaccine)
        else
          raise UnsupportedProgramme, programme
        end
      end
    end
  end
end

def side_effects_for(programme, method)
  if programme.flu?
    if method == "nasal"
      %w[runny_blocked_nose headache tiredness loss_of_appetite]
    else
      %w[
        swelling
        headache
        high_temperature
        feeling_sick
        irritable
        drowsy
        loss_of_appetite
        unwell
      ]
    end
  elsif programme.hpv?
    %w[
      swelling
      headache
      high_temperature
      feeling_sick
      irritable
      drowsy
      loss_of_appetite
      unwell
    ]
  elsif programme.menacwy?
    %w[
      drowsy
      feeling_sick
      headache
      high_temperature
      irritable
      loss_of_appetite
      rash
      swelling
      unwell
    ]
  elsif programme.td_ipv?
    %w[
      drowsy
      feeling_sick
      headache
      high_temperature
      irritable
      loss_of_appetite
      swelling
      unwell
    ]
  else
    raise UnsupportedProgramme, programme
  end
end

def create_flu_health_questions(vaccine)
  asthma =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title: "Has your child been diagnosed with asthma?",
        would_require_triage: false
      )
    end

  asthma_steroids =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title: "Does your child take oral steroids for their asthma?",
        hint: "This does not include medicine taken through an inhaler",
        give_details_hint:
          "Include the steroid name, dose and end date of the course"
      )
    end

  asthma_intensive_care =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title:
          "Has your child ever been admitted to intensive care because of their asthma?",
        hint:
          "This does not include visits to A&E or stays in hospital wards outside the intensive care unit"
      )
    end

  immune_system =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title:
          "Does your child have a disease or treatment that severely affects their immune system?",
        hint:
          "The nasal spray flu vaccine is a live vaccine. " \
            "It is not suitable for people who are severely immunocompromised."
      )
    end

  household_immune_system =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title:
          "Is your child in regular close contact with anyone currently " \
            "having treatment that severely affects their immune system?",
        give_details_hint:
          "Let us know if they are able to avoid contact with the immunocompromised person for 2 weeks"
      )
    end

  # TODO: This is only relevant for injected vaccines, but we don't know if the parents have consented to injection
  #  until after the health questions have been given.
  bleeding_disorder =
    vaccine.health_questions.create!(
      title:
        "Does your child have a bleeding disorder or are they taking anticoagulant therapy?"
    )

  egg_allergy =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title:
          "Has your child ever been admitted to intensive care due to a severe allergic reaction (anaphylaxis) to egg?",
        hint:
          "This does not include visits to A&E or stays in hospital wards outside the intensive care unit"
      )
    end

  severe_allergic_reaction =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title:
          "Has your child had a severe allergic reaction (anaphylaxis) to a " \
            "previous dose of the nasal flu vaccine, or any ingredient of the vaccine?",
        hint: "This includes gelatine, neomycin or gentamicin"
      )
    else
      vaccine.health_questions.create!(
        title:
          "Has your child had a severe allergic reaction (anaphylaxis) to a " \
            "previous dose of the injected flu vaccine, or any ingredient of the vaccine?"
      )
    end

  medical_conditions =
    vaccine.health_questions.create!(
      title:
        "Does your child have any other medical conditions the immunisation team should be aware of?",
      would_require_triage: false
    )

  aspirin =
    if vaccine.nasal?
      vaccine.health_questions.create!(
        title: "Does your child take regular aspirin?",
        hint: "Also known as Salicylate therapy"
      )
    end

  flu_previously =
    vaccine.health_questions.create!(
      title: "Has your child had a flu vaccination in the last 3 months?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious",
      would_require_triage: false
    )

  post_asthma_questions = [
    immune_system,
    household_immune_system,
    bleeding_disorder,
    egg_allergy,
    severe_allergic_reaction,
    medical_conditions,
    aspirin,
    flu_previously,
    extra_support
  ].compact

  asthma&.update!(
    follow_up_question: asthma_steroids,
    next_question: post_asthma_questions.first
  )
  asthma_steroids&.update!(next_question: asthma_intensive_care)
  asthma_intensive_care&.update!(next_question: post_asthma_questions.first)

  post_asthma_questions.each_with_index do |question, i|
    if (next_question = post_asthma_questions[i + 1])
      question.update!(next_question:)
    end
  end
end

def create_hpv_health_questions(vaccine)
  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  medical_conditions =
    vaccine.health_questions.create!(
      title:
        "Does your child have any medical conditions for which they receive treatment?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  severe_allergies.update!(next_question: medical_conditions)
  medical_conditions.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
end

def create_menacwy_health_questions(vaccine)
  bleeding_disorder =
    vaccine.health_questions.create!(
      title:
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
    )

  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  menacwy_previously =
    vaccine.health_questions.create!(
      title:
        "Has your child had a meningitis (MenACWY) vaccination in the last 5 years?",
      hint:
        "It’s usually given once in Year 9 or 10. Some children may have had it before travelling abroad."
    )

  bleeding_disorder.update!(next_question: severe_allergies)
  severe_allergies.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
  extra_support.update!(next_question: menacwy_previously)
end

def create_td_ipv_health_questions(vaccine)
  bleeding_disorder =
    vaccine.health_questions.create!(
      title:
        "Does your child have a bleeding disorder or another medical condition they receive treatment for?"
    )

  severe_allergies =
    vaccine.health_questions.create!(
      title: "Does your child have any severe allergies?"
    )

  severe_reaction =
    vaccine.health_questions.create!(
      title:
        "Has your child ever had a severe reaction to any medicines, including vaccines?"
    )

  extra_support =
    vaccine.health_questions.create!(
      title: "Does your child need extra support during vaccination sessions?",
      hint: "For example, they’re autistic, or extremely anxious"
    )

  td_ipv_previously =
    vaccine.health_questions.create!(
      title:
        "Has your child had a tetanus, diphtheria and polio vaccination in the last 5 years?",
      hint:
        "Most children will not have had this vaccination since their 4-in-1 pre-school booster"
    )

  bleeding_disorder.update!(next_question: severe_allergies)
  severe_allergies.update!(next_question: severe_reaction)
  severe_reaction.update!(next_question: extra_support)
  extra_support.update!(next_question: td_ipv_previously)
end
