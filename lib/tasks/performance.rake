# frozen_string_literal: true

desc "Get performance stats"
task :performance, [] => :environment do |_task, _args|
  include ActionView::Helpers::TextHelper

  puts "Copy and paste the following into Slack:"
  puts ""
  puts ":chart_with_upwards_trend: *PILOT PERFORMANCE* _#{Time.zone.today.to_fs(:long_day_of_week)}_"
  puts ""

  organisations =
    Organisation.all - Organisation.where(name: "Organisation MAVIS")

  patients_total =
    Patient.where(location: organisations.map(&:locations).flatten).count
  puts "#{patients_total} *Patients in cohort (total)*"

  consent_forms_total =
    ConsentForm
      .joins(:organisation)
      .where(session: { programmes: { organisation: organisations } })
      .and(ConsentForm.where.not(recorded_at: nil))
      .count
  puts "#{consent_forms_total} *Consents returned (total)*"

  vaccination_records_total =
    VaccinationRecord
      .joins(:organisation)
      .where(session: { programmes: { organisation: organisations } })
      .count
  puts "#{vaccination_records_total} *Vaccination records (total)*"

  organisations.each do |organisation|
    puts ""
    puts ":wavy_dash::wavy_dash::wavy_dash::wavy_dash::wavy_dash::wavy_dash:" \
           ":wavy_dash::wavy_dash::wavy_dash::wavy_dash:"
    puts "*:hospital: #{organisation.name}*"

    users =
      "#{organisation.users.recently_active.count}/#{organisation.users.count}"
    puts ":busts_in_silhouette: Active users: #{users} users signed in in the last week"

    organisation.programme.sessions.active.each do |session|
      puts ""
      puts ":school: *#{session.location.name}*"

      stats = PatientSessionStats.new(session.patient_sessions)
      puts "    - #{pluralize(session.location.patients.count, "child")} in cohort :racing_car:"
      puts "        - #{pluralize(stats[:with_consent_given], "child")} with consent given :white_check_mark:"
      puts "            - #{pluralize(stats[:ready_to_vaccinate], "child")} ready to vaccinate :syringe:"
      puts "        - #{pluralize(stats[:with_consent_refused], "child")} with consent refused :x:"
      puts "        - #{pluralize(stats[:without_a_response], "child")} without a response :crying_cat_face:"
    end
  end
end

# 1000 => ":one::zero::zero::zero:"
def emoji_count(number)
  number.to_s.split("").map { ":#{I18n.t("number.#{_1}")}:" }.join
end
