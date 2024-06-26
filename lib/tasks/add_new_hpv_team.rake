# frozen_string_literal: true

require_relative "../task_helpers"

desc <<-DESC
  Add a new HPV team consisting of a team, campaign, vaccine, and
  health questions.

  Usage:
    rake add_new_hpv_team # Complete the prompts
    rake add_new_hpv_team[email,name,phone,ods_code,privacy_policy_url,reply_to_id]
DESC
task :add_new_hpv_team,
     %i[email name phone ods_code privacy_policy_url reply_to_id] =>
       :environment do |_task, args|
  include TaskHelpers

  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    email = prompt_user_for "Enter team email:", required: true
    name = prompt_user_for "Enter team name:", required: true
    phone = prompt_user_for "Enter team phone:", required: true
    ods_code = prompt_user_for "Enter ODS code:"
    privacy_policy_url = prompt_user_for "Enter privacy policy URL:"
    reply_to_id = prompt_user_for "Reply-to ID (from GOVUK Notify):"
  elsif args.to_a.size == 6
    email = args[:email]
    name = args[:name]
    phone = args[:phone]
    ods_code = args[:ods_code]
    privacy_policy_url = args[:privacy_policy_url]
    reply_to_id = args[:reply_to_id]
  elsif args.to_a.size != 6
    raise "Expected 6 arguments got #{args.to_a.size}"
  end

  ActiveRecord::Base.transaction do
    team =
      Team.create!(
        email:,
        name:,
        phone:,
        ods_code:,
        privacy_policy_url:,
        reply_to_id:
      )

    campaign = Campaign.create!(name: "HPV", team:)
    vaccine =
      Vaccine.create!(type: "HPV", brand: "Gardasil 9", method: "injection")

    health_questions = []
    health_questions << HealthQuestion.create!(
      question: "Does your child have any severe allergies?",
      vaccine:
    )
    health_questions << HealthQuestion.create!(
      question:
        "Does your child have any medical conditions for which they receive treatment?",
      vaccine:
    )
    health_questions << HealthQuestion.create!(
      question:
        "Has your child ever had a severe reaction to any medicines, including vaccines?",
      vaccine:
    )
    health_questions[0].update!(next_question_id: health_questions[1].id)
    health_questions[1].update!(next_question_id: health_questions[2].id)

    campaign.vaccines << vaccine

    puts "Team #{team.name} (ID: #{team.id}) added.
  Campaign #{campaign.name} (ID: #{campaign.id}) added.
  HPV vaccine (ID: #{vaccine.id}) added."
  end
end
