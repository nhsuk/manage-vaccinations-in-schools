desc <<-DESC
  Add a new user
  Usage:
    rake add_new_user[email,password,full_name,team_id]
  Arguments:
    email: String, the email of the user.
    password: String, the password for the user account.
    full_name: String, the full name of the user.
    team_id: Integer, the ID of the team to add the user to.
    registration: String, the registration number of the user.
  Example:
    rake add_new_user['user@example.com','password123','John Doe',1,'SW608658 (HCPC)']
DESC
task :add_new_user,
     %i[email password full_name team_id registration] =>
       :environment do |_task, args|
  raise "All arguments are required" if args.to_a.size < 5

  user =
    User.create!(
      email: args[:email],
      password: args[:password],
      full_name: args[:full_name],
      registration: args[:registration]
    )
  user.teams << Team.find(args[:team_id])

  puts "User #{args[:full_name]} (#{args[:email]}) added to team #{args[:team_id]}."
end
