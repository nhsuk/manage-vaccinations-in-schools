require_relative "../task_helpers"

desc <<-DESC
  Add a new HPV team consisting of a team, campaign, vaccine, and
  health questions.

  Usage:
    rake add_new_hpv_team # Complete the prompts
    rake add_new_hpv_team[email,name,ods_code,privacy_policy_url]
DESC
task :add_new_hpv_team,
     %i[email name ods_code privacy_policy_url] => :environment do |_task, args|
  include TaskHelpers

  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    email = prompt_user_for "Enter team email:", required: true
    name = prompt_user_for "Enter name:", required: true
    ods_code = prompt_user_for "Enter ODS code:"
    privacy_policy_url = prompt_user_for "Enter privacy policy URL:"
  elsif args.to_a.size == 4
    email = args[:email]
    name = args[:name]
    ods_code = args[:ods_code]
    privacy_policy_url = args[:privacy_policy_url]
  elsif args.to_a.size != 4
    raise "Expected 4 arguments got #{args.to_a.size}"
  end

  ActiveRecord::Base.transaction do
    team = Team.create!(email:, name:, ods_code:, privacy_policy_url:)

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
