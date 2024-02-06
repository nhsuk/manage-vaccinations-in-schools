desc <<-DESC
  Add a new HPV team

  Usage:
    rake add_new_hpv_team[email,name,ods_code,privacy_policy_url]
  Arguments:
    email: String, the email of the team.
    name: String, the name of the team.
    ods_code: String, the ODS code of the team.
    privacy_policy_url: String, the URL of the team's privacy policy.
  Example:
    rake add_new_hpv_team['team@example.com','Team Name','U12345','https://example.com/privacy']
DESC
task :add_new_hpv_team,
     %i[email name ods_code privacy_policy_url] => :environment do |_task, args|
  raise "All arguments are required" if args.to_a.size < 4

  team =
    Team.create!(
      email: args[:email],
      name: args[:name],
      ods_code: args[:ods_code],
      privacy_policy_url: args[:privacy_policy_url]
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
