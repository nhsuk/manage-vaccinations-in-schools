require "readline"

desc <<-DESC
  Add a new location
  Usage:
    rake add_new_location  # You will be prompted for location info
    rake add_new_location[name,address,town,postcode,county,urn,team_id]
DESC
task :add_new_location,
     %i[name address town county urn postcode team_id] =>
       :environment do |_task, args|
  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    name = prompt_user_for "Enter name:", required: true
    address = prompt_user_for "Enter address:"
    town = prompt_user_for "Enter town:"
    county = prompt_user_for "Enter county:"
    postcode = prompt_user_for "Enter postcode:", required: true
    urn = prompt_user_for "Enter URN:"
    team_id = prompt_user_for "Enter team ID:", required: true
  elsif args.to_a.size == 7
    name = args[:name]
    address = args[:address]
    town = args[:town]
    county = args[:county]
    postcode = args[:postcode]
    urn = args[:urn]
    team_id = args[:team_id]
  elsif args.to_a.size != 7
    raise "Expected 7 arguments got #{args.to_a.size}"
  end

  location =
    Location.create!(
      name:,
      address:,
      town:,
      county:,
      urn:,
      postcode:,
      team_id:,
      registration_open: true
    )

  puts "Location #{name} (id: #{location.id}) added to team #{Team.find(team_id).name}."
  puts "New registration url:"
  base_url =
    Settings.host ? "https://#{Settings.host}" : "http://localhost:4000"
  puts base_url + "/schools/#{location.id}/registration/new"
end

def prompt_user_for(prompt, required: false)
  response = nil
  loop do
    response = Readline.readline "#{prompt} ", true
    if required && response.blank?
      puts "#{prompt} cannot be blank"
    else
      break
    end
  end
  response
end
