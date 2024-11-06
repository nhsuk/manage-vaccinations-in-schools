# frozen_string_literal: true

desc <<-DESC
  Generate sample consent forms for a session. These can be used to boostrap an
  environment and make the data look more believable.

  Usage:
    rake consent_forms:generate[session_slug]

  Example:
    rake consent_forms:generate[EprWrwjuL4]

  This will generate:
    - 10% refused consent forms
    - 50% basic consent forms
    - 20% consent forms with health answers
    - 10% consent forms with branching health answers
DESC
task :consent_forms, [:session_slug] => :environment do |_task, args|
  unless args[:session_slug]
    puts "Error: Session slug is required"
    puts "Usage: rake consent_forms:generate[session_slug]"
    exit 1
  end

  session = Session.find_by(slug: args[:session_slug])
  unless session
    puts "Error: Session not found with slug '#{args[:session_slug]}'"
    exit 1
  end

  patients = session.patient_sessions.all.filter(&:no_consent?).map(&:patient)

  puts "Found #{patients.count} patients without consent forms"
  puts "Generating consent forms..."

  # 10% refused
  patients
    .sample(patients.count * 0.1)
    .each do |patient|
      consent_form =
        FactoryBot.create(
          :consent_form,
          :refused,
          :recorded,
          session:,
          given_name: patient.given_name,
          family_name: patient.family_name,
          date_of_birth: patient.date_of_birth,
          address_postcode: patient.address_postcode
        )
      consent_form.match_with_patient!(patient)
    end

  # 50% given
  patients
    .sample(patients.count * 0.5)
    .each do |patient|
      consent_form =
        FactoryBot.create(
          :consent_form,
          :recorded,
          session:,
          given_name: patient.given_name,
          family_name: patient.family_name,
          date_of_birth: patient.date_of_birth,
          address_postcode: patient.address_postcode
        )
      consent_form.match_with_patient!(patient)
    end

  # 20% given with health questions
  patients
    .sample(patients.count * 0.2)
    .each do |patient|
      consent_form =
        FactoryBot.create(
          :consent_form,
          :with_health_answers_no_branching,
          :recorded,
          session:,
          given_name: patient.given_name,
          family_name: patient.family_name,
          date_of_birth: patient.date_of_birth,
          address_postcode: patient.address_postcode
        )
      consent_form.match_with_patient!(patient)
    end

  # 10% given with health answers branching
  patients
    .sample(patients.count * 0.10)
    .each do |patient|
      consent_form =
        FactoryBot.create(
          :consent_form,
          :with_health_answers_no_branching,
          :recorded,
          session:,
          given_name: patient.given_name,
          family_name: patient.family_name,
          date_of_birth: patient.date_of_birth,
          address_postcode: patient.address_postcode
        )
      consent_form.match_with_patient!(patient)
    end

  puts "Successfully generated consent forms"
end
