# frozen_string_literal: true

desc <<-DESC
  Send consent reminders for a session to all patient's parents who've not returned consent yet
DESC
task :send_consent_reminders, %i[session_id] => :environment do |_task, args|
  session = Session.find(args[:session_id])
  patients = session.patients.without_consent

  puts "Team: #{session.team.name}"
  puts "Location: #{session.location.name}"
  puts "Session consent close date: #{session.close_consent_at}"
  response =
    Readline.readline "#{patients.count} patients without consent. Send consent reminders? (y/N) "

  if response.downcase.starts_with? "y"
    patients.each do |patient|
      puts "sending mail for patient #{patient.id}"
      ConsentRequestMailer.consent_reminder(session, patient).deliver_now
    end
  end
end
