desc <<-DESC
  Add a new user with a secured password

  The user's password will be randomly generated and not displayed. The user
  will need to reset their password to use the account.

  Usage:
    rake add_new_user[email,full_name,team_id]
  Arguments:
    email: String, the email of the user.
    full_name: String, the full name of the user.
    team_id: Integer, the ID of the team to add the user to.
  Example:
    rake add_new_user_securely['user@example.com','John Doe',1]
DESC
task :add_new_user_securely,
     %i[email full_name team_id] => :environment do |_task, args|
  raise "All arguments are required" if args.to_a.size < 3

  password = SecureRandom.uuid

  user =
    User.create!(email: args[:email], password:, full_name: args[:full_name])
  user.teams << Team.find(args[:team_id])

  puts "User #{args[:full_name]} (#{args[:email]}) added to team #{args[:team_id]}."

  user.send_reset_password_instructions
  puts "Password reset instructions sent."
end
