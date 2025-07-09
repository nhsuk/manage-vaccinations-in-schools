# frozen_string_literal: true

namespace :consent_forms do
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
  task :generate, [:session_slug] => :environment do |_task, args|
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

    patient_sessions = session.patient_sessions.includes(patient: [:consent_statuses, :vaccination_statuses])

    patients = patient_sessions.map(&:patient)

    puts "Found #{patients.count} patients in the session"
    puts "Generating consent forms..."

    create_consent_forms = lambda do |patients, percentage, session, *traits|
      patients
        .sample((patients.count * percentage).ceil)
        .each do |patient|
          eligible_programmes = session.programmes.select do |programme|
            patient.consent_status(programme: programme).no_response? && 
            !patient.vaccination_status(programme: programme).vaccinated?
          end

          next if eligible_programmes.empty?

          consent_form =
            FactoryBot.create(
              :consent_form,
              *traits,
              :recorded,
              session:,
              given_name: patient.given_name,
              family_name: patient.family_name,
              date_of_birth: patient.date_of_birth,
              address_postcode: patient.address_postcode,
              programmes: eligible_programmes
            )
          consent_form.match_with_patient!(patient, current_user: nil)
        end
    end

    # 10% refused
    create_consent_forms.call(patients, 0.1, session, :refused)

    # 50% given
    create_consent_forms.call(patients, 0.5, session)

    # 20% given with health questions
    create_consent_forms.call(patients, 0.2, session, :with_health_answers_no_branching)

    # 10% given with health answers branching
    create_consent_forms.call(patients, 0.1, session, :with_health_answers_asthma_branching)

    puts "Successfully generated consent forms"
  end
end
