# frozen_string_literal: true

require_relative "../task_helpers"

desc <<-DESC
  Add health questions to a vaccine.

  Usage:
    rake add_health_questions[team_id,vaccine_id,replace]

  The vaccine must belong to the team given, this is a safety check.

  Use "replace" for the replace arg to replace the existing health questions.

  Example:

    rake add_health_questions[1,1,replace]
DESC
task :add_health_questions,
     %i[team_id vaccine_id replace] => :environment do |_task, args|
  team = Team.find(args[:team_id])
  vaccine = team.programme.vaccines.find(args[:vaccine_id])
  existing_health_questions = vaccine.health_questions.in_order
  puts "Existing health questions for #{team.name}'s #{vaccine.type} vaccine #{vaccine.brand}"
  if existing_health_questions.any?
    existing_health_questions.each do |health_question|
      puts Rainbow("  #{health_question.question}").yellow
    end
  else
    puts Rainbow("  [none]").black
  end

  puts ""
  print "Enter health questions line-by-line below."

  replace = args[:replace]&.downcase == "replace"
  if replace
    if existing_health_questions.any?
      puts Rainbow(" These health questions will replace the ones above.").red
    end
  else
    puts " These health questions will added to the ones above."
  end

  puts ""
  puts "Enter an empty line to finish."

  health_questions = []
  num = replace ? 0 : existing_health_questions.count - 1
  loop do
    response =
      Readline.readline Rainbow("health question #{num + 1}: ").green, true
    break if response == ""
    health_questions[num] = response
    num += 1
  end

  if health_questions.empty?
    puts "No responses entered, quitting"
    next
  end

  puts "\nThese will be the health questions for #{team.name}'s #{vaccine.type} vaccine #{vaccine.brand}:"
  unless replace
    existing_health_questions.each do |health_question|
      puts Rainbow("  [old] #{health_question.question}").black
    end
  end
  health_questions.each do |health_question|
    puts Rainbow("  [new] #{health_question}").white
  end

  puts ""
  response = Readline.readline "Continue? (y/N) "
  if response[0].downcase == "y"
    update_health_questions(vaccine:, health_questions:, replace:)
    puts Rainbow("Health questions added").green
  else
    puts Rainbow("Exiting without adding health questions").red
  end
end

def update_health_questions(vaccine:, health_questions:, replace:)
  vaccine.health_questions.delete_all if replace

  last_question = vaccine.health_questions.last_health_question unless replace

  hq_objects =
    health_questions.map do |health_question|
      HealthQuestion.new(question: health_question)
    end
  vaccine.health_questions << hq_objects

  last_id = nil
  hq_objects.reverse.each do |hq|
    hq.update!(next_question_id: last_id) if last_id.present?
    last_id = hq.id
  end

  if last_question.present?
    last_question.update!(next_question: hq_objects.first)
  end
end
